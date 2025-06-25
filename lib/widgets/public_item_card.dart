import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../helpers/ui_helpers.dart'; // --- NEW: Import the helper file ---

class PublicItemCard extends StatelessWidget {
  final Item item;

  const PublicItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Hero(
                  tag: 'public_item_${item.id}',
                  child: Container(
                    color: Colors.grey[200],
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 40, color: AppTheme.lightText),
                          )
                        : const Icon(Icons.image_not_supported, size: 40, color: AppTheme.lightText),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Còn: ${item.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.brand, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(item.category, style: Theme.of(context).textTheme.bodySmall),
                      Text('Màu: ${item.color}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.lightText)),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${item.price.toInt()} cá',
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryPink,
                            fontWeight: FontWeight.bold
                          ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.accentPink),
                        tooltip: 'Thêm vào giỏ',
                        onPressed: () {
                          final success = cartService.addToCart(item);
                          
                          // --- UPDATE: Use the new helper function ---
                          if (success) {
                            showTopSnackBar(context, 'Đã thêm "${item.brand}" vào giỏ hàng.');
                          } else {
                             showTopSnackBar(context, 'Số lượng sản phẩm trong kho không đủ.', isError: true);
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
