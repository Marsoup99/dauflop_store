import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // --- NEW: Import for clipboard functionality
import '../models/item_model.dart';
import '../services/cart_service.dart';
import '../widgets/public_item_card.dart';
import '../screens/cart_screen.dart';
import '../theme/app_theme.dart';

class PublicStoreScreen extends StatefulWidget {
  const PublicStoreScreen({super.key});

  @override
  State<PublicStoreScreen> createState() => _PublicStoreScreenState();
}

class _PublicStoreScreenState extends State<PublicStoreScreen> {
  String _activeSearchQuery = '';
  String? _selectedCategory;
  List<Item> _allItems = []; 
  final SearchController _searchController = SearchController();
  final CartService _cartService = CartService();

  int _currentPage = 1;
  final int _itemsPerPage = 18;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _commitSearch(String query) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _activeSearchQuery = query.toLowerCase();
      _currentPage = 1; 
    });
  }

  void _onCategoryChanged(String? newValue) {
    setState(() {
      _selectedCategory = newValue;
      _currentPage = 1; 
    });
  }

  void _showAboutDialog() {
    const zaloNumber = '0368267654'; // Define the number here for re-use
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Về DauFlop Store"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  "Shop hàng nhỏ lẻ bán hàng zui zẻ",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // --- UPDATE: Replaced SelectableText with a Row for better UX ---
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Liên hệ tư vấn qua Zalo: $zaloNumber",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 22),
                      tooltip: 'Sao chép SĐT Zalo',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: zaloNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép số Zalo!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.lightPinkBackground,
        elevation: 1,
        
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Giới thiệu',
          onPressed: _showAboutDialog,
        ),

        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/my_logo.png',
              height: 28, 
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.storefront, color: AppTheme.lightPinkBackground);
              },
            ),
            const SizedBox(width: 8),
            const Text("Store của Đậu"),
          ],
        ),
        centerTitle: true,

        actions: [
          ValueListenableBuilder<List>(
            valueListenable: _cartService.cart,
            builder: (context, cartItems, child) {
              return Badge(
                label: Text('${_cartService.totalItems}'),
                isLabelVisible: cartItems.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('quantity', isGreaterThan: 0)
            .orderBy('lastModified', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          _allItems = snapshot.data?.docs.map((doc) {
            return Item.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList() ?? [];

          final categories = {'Tất cả', ..._allItems.map((item) => item.category)}.toList();
          
          final filteredItems = _allItems.where((item) {
            final searchMatch = _activeSearchQuery.isEmpty ||
                item.brand.toLowerCase().contains(_activeSearchQuery) ||
                item.category.toLowerCase().contains(_activeSearchQuery) ||
                item.color.toLowerCase().contains(_activeSearchQuery);
            
            final categoryMatch = _selectedCategory == null ||
                _selectedCategory == 'Tất cả' ||
                item.category == _selectedCategory;

            return searchMatch && categoryMatch;
          }).toList();

          final totalItems = filteredItems.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          if (totalPages > 0 && _currentPage > totalPages) {
            _currentPage = totalPages;
          } else if (totalPages == 0) {
            _currentPage = 1;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = min(startIndex + _itemsPerPage, totalItems);
          final itemsForCurrentPage = filteredItems.sublist(startIndex, endIndex);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    SearchAnchor(
                      searchController: _searchController,
                      builder: (BuildContext context, SearchController controller) {
                        return SearchBar(
                          controller: controller,
                          constraints: const BoxConstraints(maxWidth: 400, minWidth: 250),
                          hintText: 'Tìm kiếm sản phẩm...',
                          leading: const Icon(Icons.search),
                          onTap: () => controller.openView(),
                          onChanged: (_) => controller.openView(),
                          onSubmitted: (query) => _commitSearch(query),
                          trailing: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Tìm kiếm',
                              onPressed: () => _commitSearch(controller.text),
                            ),
                          ],
                        );
                      },
                      suggestionsBuilder: (BuildContext context, SearchController controller) {
                        final keyword = controller.text.toLowerCase();
                        if (keyword.isEmpty) return <Widget>[];

                        final suggestions = _allItems.expand((item) => [item.brand, item.category])
                            .toSet() 
                            .where((suggestion) => suggestion.toLowerCase().contains(keyword))
                            .toList();

                        return suggestions.map((s) => ListTile(
                          title: Text(s),
                          onTap: () {
                            controller.closeView(s);
                            _commitSearch(s);
                          },
                        ));
                      },
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory ?? 'Tất cả',
                        isDense: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: itemsForCurrentPage.isEmpty
                  ? const Center(child: Text('Không tìm thấy sản phẩm nào.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = (constraints.maxWidth / 200).floor();
                        if (crossAxisCount < 2) crossAxisCount = 2;

                        const double cardPadding = 12.0;
                        final double itemWidth = (constraints.maxWidth - (cardPadding * (crossAxisCount + 1))) / crossAxisCount;
                        const double textHeight = 150; 
                        final double itemHeight = itemWidth + textHeight;
                        final double childAspectRatio = itemWidth / itemHeight;

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, cardPadding),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: cardPadding,
                            mainAxisSpacing: cardPadding,
                          ),
                          itemCount: itemsForCurrentPage.length,
                          itemBuilder: (context, index) {
                            return PublicItemCard(item: itemsForCurrentPage[index]);
                          },
                        );
                      }
                    ),
              ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text(
                        'Trang $_currentPage / $totalPages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
