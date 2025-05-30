import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // bool _isProcessingPendingAction = false;
  // final Set<String> _processingMoveToPending = {};

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
    // Also clear the active search query when clearing the text field
    setState(() {
      _searchController.clear();
      _activeSearchQuery = '';
    });
  }

  // --- SIMPLIFIED: _markItemAsPending no longer manages UI loading state ---
  Future<void> _markItemAsPending(Item item) async {
    // Removed: Client-side check for _processingMoveToPending.contains(item.id!)
    // Removed: setState for _processingMoveToPending.add/remove

    if (item.id == null) { // Should not happen if items come from Firestore
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item ID is missing.'), backgroundColor: Colors.red));
        return;
    }
    
    const int quantityToMoveToPending = 1;
    DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(item.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentItemSnapshot = await transaction.get(itemRef);
        if (!currentItemSnapshot.exists) {
          throw Exception("Item does not exist!");
        }
        int currentQuantity = (currentItemSnapshot.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
        if (currentQuantity < quantityToMoveToPending) {
          throw Exception('Not enough stock. On shelf: $currentQuantity');
        }

        transaction.update(itemRef, {
          'quantity': FieldValue.increment(-quantityToMoveToPending),
          'lastModified': Timestamp.now(),
        });

        final pendingSaleData = {
          'itemId': item.id,
          'itemName': '${item.brand} - ${item.category}',
          'itemColor': item.color,
          'imageUrl': item.imageUrl,
          'quantityPending': quantityToMoveToPending,
          'buyInPriceAtPending': item.buyInPrice,
          'sellPriceAtPending': item.price,
          'pendingTimestamp': Timestamp.now(),
        };
        DocumentReference pendingSaleRef = FirebaseFirestore.instance.collection('pending_sales').doc();
        transaction.set(pendingSaleRef, pendingSaleData);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('1 unit of ${item.brand} - ${item.category} moved to pending.'), backgroundColor: Colors.blueAccent),
        );
      }
    } catch (e) {
      print('Error moving item to pending: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move item to pending: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
      // Re-throw the error if you want the InventoryItemTile to also catch it
      // and potentially handle its _isProcessing state differently on failure.
      // For now, the tile's finally block will reset _isProcessing.
    }
    // Removed: finally block that called setState for _processingMoveToPending
  }

  // --- UPDATED: Method to Confirm a Pending Sale ---
  Future<void> _confirmPendingSale(PendingSale pendingSale) async {
    // Removed: setState for _isProcessingPendingAction

    try {
      final double profitOnSale = (pendingSale.sellPriceAtPending - pendingSale.buyInPriceAtPending) * pendingSale.quantityPending;
      final salesTransactionData = {
        'itemId': pendingSale.itemId,
        'itemName': pendingSale.itemName,
        'itemColor': pendingSale.itemColor,
        'imageUrl': pendingSale.imageUrl,
        'quantitySold': pendingSale.quantityPending,
        'buyInPriceAtSale': pendingSale.buyInPriceAtPending,
        'sellPriceAtSale': pendingSale.sellPriceAtPending,
        'profitOnSale': profitOnSale,
        'finalSaleTimestamp': Timestamp.now(),
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference salesTxRef = FirebaseFirestore.instance.collection('sales_transactions').doc();
      batch.set(salesTxRef, salesTransactionData);
      DocumentReference pendingSaleRef = FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id);
      batch.delete(pendingSaleRef);
      DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId);
      batch.update(itemRef, {'lastModified': Timestamp.now()});
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale confirmed for ${pendingSale.itemName}!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error confirming sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm sale: $e'), backgroundColor: Colors.redAccent),
        );
      }
      rethrow; // Re-throw so the tile can catch it if needed for its own state
    }
    // Removed: finally block setting _isProcessingPendingAction
  }

  // --- SIMPLIFIED: _cancelPendingSale ---
  Future<void> _cancelPendingSale(PendingSale pendingSale) async {
    // Removed: setState for _isProcessingPendingAction

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(pendingSale.itemId);
      batch.update(itemRef, {
        'quantity': FieldValue.increment(pendingSale.quantityPending),
        'lastModified': Timestamp.now(),
      });
      DocumentReference pendingSaleRef = FirebaseFirestore.instance.collection('pending_sales').doc(pendingSale.id);
      batch.delete(pendingSaleRef);
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pending sale for ${pendingSale.itemName} cancelled.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      print('Error cancelling sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel sale: $e'), backgroundColor: Colors.redAccent),
        );
      }
      rethrow; // Re-throw
    }
    // Removed: finally block setting _isProcessingPendingAction
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Management'),
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent, // Example customization
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.black38,
            tabs: [
              Tab(icon: Icon(Icons.store_mall_directory_outlined), text: 'In Stock'),
              Tab(icon: Icon(Icons.hourglass_top_outlined), text: 'Pending Sales'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStorageTab(),
            _buildPendingSalesTab(), // This will be implemented next
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Term',
                    hintText: 'Brand, Category, Color...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) {
                    // if (mounted) {
                    //   setState(() {}); // For suffixIcon visibility
                    // }
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16)
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            ),
            value: (_selectedCategory != null && categories.contains(_selectedCategory))
                   ? _selectedCategory
                   : "All Categories",
            hint: const Text('Filter by Category'),
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
                // _performSearch(); // Optional: trigger search on category change
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .orderBy('lastModified', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) { return Center(child: Text('Error: ${snapshot.error}')); }
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        
        List<Item> allItems = snapshot.data?.docs
            .map((doc) => Item.fromMap(doc.data()! as Map<String, dynamic>, doc.id))
            .toList() ?? [];

        if (allItems.isEmpty) {
           return Column(children: [_buildFilterControls([]), const Expanded(child: Center(child: Text('No items in stock.')))]);
        }
        
        List<String> categories = ["All Categories"];
        Set<String> uniqueCategories = {};
        for (var item in allItems) { if (item.category.isNotEmpty) uniqueCategories.add(item.category); }
        categories.addAll(uniqueCategories.toList()..sort());

        final List<Item> filteredItems = allItems.where((item) {
          bool categoryMatch = _selectedCategory == null || _selectedCategory == "All Categories" || item.category.toLowerCase() == _selectedCategory!.toLowerCase();
          bool searchMatch = _activeSearchQuery.isEmpty || item.brand.toLowerCase().contains(_activeSearchQuery) || item.category.toLowerCase().contains(_activeSearchQuery) || item.color.toLowerCase().contains(_activeSearchQuery);
          return categoryMatch && searchMatch;
        }).toList();
        
        if (_selectedCategory != null && !categories.contains(_selectedCategory) && _selectedCategory != "All Categories") {
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _selectedCategory = "All Categories"); });
        }

        return Column(
          children: [
            _buildFilterControls(categories),
            if (filteredItems.isEmpty)
              const Expanded(child: Center(child: Text('No items match your criteria.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    Item item = filteredItems[index];
                    // --- USE THE NEW InventoryItemTile ---
                    return InventoryItemTile(
                      key: ValueKey(item.id), // Important for stateful list items
                      item: item,
                      onMarkItemAsPending: _markItemAsPending, // Pass the method
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPendingSalesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_sales')
          .orderBy('pendingTimestamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) { return Center(child: Text('Something went wrong: ${snapshot.error}')); }
        if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) { return const Center(child: Text('No sales are currently pending confirmation.')); }

        return ListView.builder( // Changed to ListView.builder
          itemCount: snapshot.data!.docs.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            DocumentSnapshot document = snapshot.data!.docs[index];
            PendingSale pendingSale = PendingSale.fromMap(document.data()! as Map<String, dynamic>, document.id);

            // --- USE THE NEW PendingSaleItemTile ---
            return PendingSaleItemTile(
              key: ValueKey(pendingSale.id), // Important for stateful list items
              pendingSale: pendingSale,
              onConfirm: _confirmPendingSale, // Pass the method
              onCancel: _cancelPendingSale,   // Pass the method
            );
          },
        );
      },
    );
  }
}