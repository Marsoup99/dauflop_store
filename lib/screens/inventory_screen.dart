import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/item_model.dart';
import 'widgets/inventory_item_tile.dart';
import 'add_item_screen.dart';

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

  // void _clearSearch() {
  //   setState(() {
  //     _searchController.clear();
  //     _activeSearchQuery = '';
  //   });
  // }

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

  Future<void> _deleteItem(Item item) async {
    print(item.id);
    if (item.id == null) return;

    // Show a confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete "${item.brand} - ${item.category}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User cancels
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true), // User confirms
            style: FilledButton.styleFrom(backgroundColor: Colors.red[100]),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If the user did not confirm, do nothing
    if (shouldDelete != true) {
      return;
    }

    try {
      // NOTE: This will delete the item from stock. It will NOT affect historical
      // sales_transactions, which is generally the desired behavior.
      // We should also delete any pending_sales for this item.
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Delete the item from the main 'items' collection
      batch.delete(FirebaseFirestore.instance.collection('items').doc(item.id));

      // 2. Find and delete all pending sales associated with this item
      QuerySnapshot pendingSalesSnapshot = await FirebaseFirestore.instance
          .collection('pending_sales')
          .where('itemId', isEqualTo: item.id)
          .get();
      
      for (var doc in pendingSalesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error deleting item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _navigateToEditItem(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(itemToEdit: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Stock'),
      ),
      body: _buildStorageTab(),
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
                    spacing: 12.0,
                    runSpacing: 12.0,
                    alignment: WrapAlignment.start,
                    children: filteredItems.map((item) {
                      return Container(
                        width: 180,
                        child: InventoryItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          onMarkItemAsPending: _markItemAsPending,
                          // --- PASS THE NEW CALLBACK ---
                          onEdit: _navigateToEditItem,
                          onDelete: _deleteItem,
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

}
