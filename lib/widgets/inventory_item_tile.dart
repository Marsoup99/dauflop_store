import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

class InventoryItemTile extends StatefulWidget {
  final Item item;
  final Future<void> Function(Item item) onMarkItemAsPending;
  final void Function(Item item) onEdit;
  final void Function(Item item) onDelete;
  final void Function() onImageTap;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onMarkItemAsPending,
    required this.onEdit,
    required this.onDelete,
    required this.onImageTap,
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
    bool hasImage = widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This AspectRatio widget will force its child to be square.
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- UPDATED: Image is now wrapped for interactivity ---
                Hero(
                  tag: 'item_image_${widget.item.id}', // Unique tag for the animation
                  child: Material( // Material is needed for the InkWell splash effect
                    color: Colors.transparent,
                    child: InkWell( // Use InkWell for tap effect
                      onTap: hasImage ? widget.onImageTap : null,
                      child: Container(
                        color: Colors.grey[200],
                        child: hasImage
                            ? Image.network(
                                widget.item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40, color: AppTheme.lightText),
                                )
                            : const Icon(Icons.image_not_supported, size: 40, color: AppTheme.lightText),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit(widget.item);
                        } else if (value == 'delete') {
                          widget.onDelete(widget.item);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Chỉnh Sửa'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Xóa Sản Phẩm', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // The text content below the image. No Expanded/Spacer needed.
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
                  'Color: ${widget.item.color}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.lightText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
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
