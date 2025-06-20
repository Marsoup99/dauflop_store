import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class PublicItemCard extends StatelessWidget {
  final Item item;

  const PublicItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image takes up a portion of the card height
          AspectRatio(
            aspectRatio: 1.0, // This makes the image container square
            child: Container(
              color: Colors.grey[200],
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40, color: AppTheme.lightText),
                    )
                  : const Icon(Icons.image_not_supported, size: 40, color: AppTheme.lightText),
            ),
          ),
          
          // Text content below the image
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.bold
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
