import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/item_model.dart';
import '../models/pending_sale_model.dart';
import 'widgets/inventory_item_tile.dart';
import 'widgets/pending_sale_item_tile.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeSearchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _activeSearchQuery = _searchController.text.toLowerCase();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _activeSearchQuery = '';
    });
  }

  // --- NEW: Dialog to get negotiated price ---
  Future<double?> _showNegotiatedPriceDialog(Item item) async {
    final priceController = TextEditingController(text: item.price.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    return showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Pending Sale Price'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${item.brand} - ${item.category}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Negotiated Sell Price',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Price cannot be empty.';
                    if (double.tryParse(value) == null) return 'Please enter a valid number.';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel returns null
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(double.parse(priceController.text));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // --- UPDATED: Method to mark an item as pending ---
  Future<void> _markItemAsPending(Item item) async {
    if (item.quantity <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item is out of stock!'), backgroundColor: Colors.orange));
      return;
    }

    // Show dialog to get the negotiated price
    final negotiatedPrice = await _showNegotiatedPriceDialog(item);

    // If the user cancelled the dialog, do nothing
    if (negotiatedPrice == null) return;

    const int quantityToMoveToPending = 1;
    final pendingSaleData = {
      'itemId': item.id,
      'itemName': '${item.brand} - ${item.category}',
      'itemColor': item.color,
      'imageUrl': item.imageUrl,
      'quantityPending': quantityToMoveToPending,
      'buyInPriceAtPending': item.buyInPrice,
      'sellPriceAtPending': negotiatedPrice, // Use the negotiated price
      'pendingTimestamp': Timestamp.now(),
    };

    DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(item.id);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentItemSnapshot = await transaction.get(itemRef);
        if (!currentItemSnapshot.exists) throw Exception("Item does not exist!");
        int currentQuantity = (currentItemSnapshot.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
        if (currentQuantity < quantityToMoveToPending) throw Exception('Not enough stock.');
        
        transaction.update(itemRef, {'quantity': FieldValue.increment(-quantityToMoveToPending), 'lastModified': Timestamp.now()});
        
        DocumentReference pendingSaleRef = FirebaseFirestore.instance.collection('pending_sales').doc();
        transaction.set(pendingSaleRef, pendingSaleData);
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved 1 ${item.brand} to pending at \$${negotiatedPrice.toStringAsFixed(2)}.'), backgroundColor: Colors.blueAccent));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to move to pending: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _confirmPendingSale(PendingSale pendingSale) async {
    try {
      final profit = (pendingSale.sellPriceAtPending - pendingSale.buyInPriceAtPending) * pendingSale.quantityPending;
      final transactionData = { 'itemId': pendingSale.itemId, 'itemName': pendingSale.itemName, 'itemColor': pendingSale.itemColor, 'imageUrl': pendingSale.imageUrl, 'quantitySold': pendingSale.quantityPending, 'buyInPriceAtSale': pendingSale.buyInPriceAtPending, 'sellPriceAtSale': pendingSale.sellPriceAtPending, 'profitOnSale': profit, 'finalSaleTimestamp': Timestamp.now()};
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.set(FirebaseFirestore.instance.collection('sales_transactions').doc(), transactionData);
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'lastModified': Timestamp.now()});
      await batch.commit();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sale confirmed!'), backgroundColor: Colors.green));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to confirm sale: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _cancelPendingSale(PendingSale pendingSale) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId), {'quantity': FieldValue.increment(pendingSale.quantityPending), 'lastModified': Timestamp.now()});
      batch.delete(FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id));
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pending sale cancelled.'), backgroundColor: Colors.orange));
    } catch(e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel sale: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Management'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.storefront_outlined), text: 'In Stock'),
              Tab(icon: Icon(Icons.hourglass_top_outlined), text: 'Pending Sales'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStorageTab(),
            _buildPendingSalesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Brand, Category, Color...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (categories.length > 1)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'Filter by Category'),
              value: (_selectedCategory != null && categories.contains(_selectedCategory))
                     ? _selectedCategory
                     : "All Categories",
              isExpanded: true,
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return StreamBuilder<QuerySnapshot>(
      // --- CHANGE HERE: Sort by a stable field like 'brand' alphabetically ---
      stream: FirebaseFirestore.instance.collection('items').orderBy('brand').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        List<Item> allItems = snapshot.data?.docs.map((doc) => Item.fromMap(doc.data()! as Map<String, dynamic>, doc.id)).toList() ?? [];

        List<String> categories = ["All Categories", ...{ for (var item in allItems) if (item.category.isNotEmpty) item.category }.toList()..sort()];

        final List<Item> filteredItems = allItems.where((item) {
          bool categoryMatch = _selectedCategory == null || _selectedCategory == "All Categories" || item.category.toLowerCase() == _selectedCategory!.toLowerCase();
          bool searchMatch = _activeSearchQuery.isEmpty || item.brand.toLowerCase().contains(_activeSearchQuery) || item.category.toLowerCase().contains(_activeSearchQuery) || item.color.toLowerCase().contains(_activeSearchQuery);
          return categoryMatch && searchMatch;
        }).toList();
        
        return Column(
          children: [
            _buildFilterControls(categories),
            if (filteredItems.isEmpty)
              const Expanded(child: Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No items match your criteria.', textAlign: TextAlign.center))))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 12.0, // Horizontal space between cards
                    runSpacing: 12.0, // Vertical space between rows of cards
                    alignment: WrapAlignment.start,
                    children: filteredItems.map((item) {
                      // Each card is given a width so the Wrap widget knows how many to fit per line
                      return Container(
                        width: 180, // Set a base width for each card
                        child: InventoryItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          onMarkItemAsPending: _markItemAsPending,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPendingSalesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pending_sales').orderBy('pendingTimestamp', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Center(child: Text('Something went wrong: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No sales are currently pending confirmation.', textAlign: TextAlign.center)));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            PendingSale pendingSale = PendingSale.fromMap(document.data()! as Map<String, dynamic>, document.id);
            return PendingSaleItemTile(
              key: ValueKey(pendingSale.id),
              pendingSale: pendingSale,
              onConfirm: _confirmPendingSale,
              onCancel: _cancelPendingSale,
            );
          },
        );
      },
    );
  }
}
