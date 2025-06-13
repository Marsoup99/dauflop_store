import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../localizations/app_localizations.dart'; // Import localization service
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

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _activeSearchQuery = '';
    });
  }

  void _navigateToEditItem(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(itemToEdit: item),
      ),
    );
  }

  Future<double?> _showNegotiatedPriceDialog(Item item) async {
    final loc = AppLocalizations.of(context);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    return showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('confirm_negotiated_price_title')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${loc.translate('item_label')}: ${item.brand} - ${item.category}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: loc.translate('negotiated_sell_price_label'),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return loc.translate('validation_enter_sell_price');
                    if (double.tryParse(value) == null) return loc.translate('error_invalid_number');
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.translate('dialog_cancel_button')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(double.parse(priceController.text));
                }
              },
              child: Text(loc.translate('confirm_button')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markItemAsPending(Item item) async {
    final loc = AppLocalizations.of(context);
    if (item.quantity <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('item_out_of_stock')), backgroundColor: Colors.orange));
      return;
    }
    final negotiatedPrice = await _showNegotiatedPriceDialog(item);
    if (negotiatedPrice == null) return;
    
    const int quantityToMoveToPending = 1;
    final pendingSaleData = { 'itemId': item.id, 'itemName': '${item.brand} - ${item.category}', 'itemColor': item.color, 'imageUrl': item.imageUrl, 'quantityPending': quantityToMoveToPending, 'buyInPriceAtPending': item.buyInPrice, 'sellPriceAtPending': negotiatedPrice, 'pendingTimestamp': Timestamp.now() };
    DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(item.id);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentItemSnapshot = await transaction.get(itemRef);
        if (!currentItemSnapshot.exists) throw Exception(loc.translate('error_item_not_exist'));
        int currentQuantity = (currentItemSnapshot.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
        if (currentQuantity < quantityToMoveToPending) throw Exception(loc.translate('error_not_enough_stock'));
        
        transaction.update(itemRef, {'quantity': FieldValue.increment(-quantityToMoveToPending), 'lastModified': Timestamp.now()});
        DocumentReference pendingSaleRef = FirebaseFirestore.instance.collection('pending_sales').doc();
        transaction.set(pendingSaleRef, pendingSaleData);
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('moved_to_pending_message', params: {'item_name': '${item.brand} - ${item.category}', 'price': negotiatedPrice.toStringAsFixed(2)})), backgroundColor: Colors.blueAccent));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('failed_to_move_to_pending_message', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _deleteItem(Item item) async {
    final loc = AppLocalizations.of(context);
    if (item.id == null) return;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('delete_item_confirm_title')),
        content: Text(loc.translate('delete_item_confirm_content', params: {'item_name': '${item.brand} - ${item.category}'})),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(loc.translate('dialog_cancel_button'))),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[100]),
            child: Text(loc.translate('delete_button'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.delete(FirebaseFirestore.instance.collection('items').doc(item.id!));
      QuerySnapshot pendingSalesSnapshot = await FirebaseFirestore.instance.collection('pending_sales').where('itemId', isEqualTo: item.id).get();
      for (var doc in pendingSalesSnapshot.docs) { batch.delete(doc.reference); }
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('item_deleted_success')), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('item_deleted_fail', params: {'error': e.toString()})), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('in_stock'))),
      body: _buildStorageTab(),
    );
  }

  Widget _buildFilterControls(List<String> categories, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(hintText: loc.translate('search_hint'), prefixIcon: const Icon(Icons.search)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _performSearch, child: Text(loc.translate('search_button'))),
            ],
          ),
          const SizedBox(height: 10),
          if (categories.length > 1)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(hintText: loc.translate('filter_by_category_hint')),
              value: (_selectedCategory != null && categories.contains(_selectedCategory)) ? _selectedCategory : loc.translate('all_categories'),
              isExpanded: true,
              items: categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    final loc = AppLocalizations.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').orderBy('brand').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Center(child: Text('Ui, có lỗi rùi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        List<Item> allItems = snapshot.data?.docs.map((doc) => Item.fromMap(doc.data()! as Map<String, dynamic>, doc.id)).toList() ?? [];
        List<String> categories = [loc.translate('all_categories'), ...{ for (var item in allItems) if (item.category.isNotEmpty) item.category }.toList()..sort()];

        final List<Item> filteredItems = allItems.where((item) {
          bool categoryMatch = _selectedCategory == null || _selectedCategory == loc.translate('all_categories') || item.category.toLowerCase() == _selectedCategory!.toLowerCase();
          bool searchMatch = _activeSearchQuery.isEmpty || item.brand.toLowerCase().contains(_activeSearchQuery) || item.category.toLowerCase().contains(_activeSearchQuery) || item.color.toLowerCase().contains(_activeSearchQuery);
          return categoryMatch && searchMatch;
        }).toList();
        
        return Column(
          children: [
            _buildFilterControls(categories, loc),
            if (filteredItems.isEmpty)
              Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(loc.translate('no_items_found'), textAlign: TextAlign.center))))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    alignment: WrapAlignment.start,
                    children: filteredItems.map((item) {
                      return SizedBox(
                        width: 180, 
                        child: InventoryItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          onMarkItemAsPending: _markItemAsPending,
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
