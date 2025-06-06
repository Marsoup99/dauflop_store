import 'package:flutter/material.dart';
import '../../models/item_model.dart';
import '../../theme/app_theme.dart';

class InventoryItemTile extends StatefulWidget {
  final Item item;
  final Future<void> Function(Item item) onMarkItemAsPending;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onMarkItemAsPending,
  });

  @override
  State<InventoryItemTile> createState() => _InventoryItemTileState();
}

class _InventoryItemTileState extends State<InventoryItemTile> {
  bool _isProcessing = false;

  Future<void> _handleMarkAsPending() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onMarkItemAsPending(widget.item);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canMarkPending = widget.item.quantity > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image part of the card
          Container(
            height: 130, // Fixed height for the image area
            width: double.infinity,
            color: Colors.grey[200],
            child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                ? Image.network(
                    widget.item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 40, color: AppTheme.lightText),
                  )
                : const Icon(Icons.image_not_supported, size: 40, color: AppTheme.lightText),
          ),
          
          // Text and action part of the card
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.brand,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.item.category,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.item.color,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8), // Use SizedBox for spacing
                // Price and Action Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                          '\$${widget.item.buyInPrice.toStringAsFixed(2)}',
                           style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.lightText,
                              fontWeight: FontWeight.bold
                            ),
                        ),
                         Text(
                          '\$${widget.item.price.toStringAsFixed(2)}',
                           style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.bold
                            ),
                        ),
                        Text(
                          'Stock: ${widget.item.quantity}',
                           style: Theme.of(context).textTheme.bodySmall,
                        ),
                       ],
                    ),
                    _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPink),
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: canMarkPending ? AppTheme.accentPink.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.add_shopping_cart_outlined,
                              color: canMarkPending ? AppTheme.accentPink : Colors.grey,
                              size: 20,
                            ),
                            tooltip: 'Move 1 to Pending Sale',
                            onPressed: canMarkPending ? _handleMarkAsPending : null,
                          ),
                        )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}