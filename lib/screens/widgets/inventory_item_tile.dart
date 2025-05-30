import 'package:flutter/material.dart';
import '../../models/item_model.dart'; // Your Item model

class InventoryItemTile extends StatefulWidget {
  final Item item;
  final Future<void> Function(Item item) onMarkItemAsPending; // Callback

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onMarkItemAsPending,
  });

  @override
  State<InventoryItemTile> createState() => _InventoryItemTileState();
}

class _InventoryItemTileState extends State<InventoryItemTile> {
  bool _isProcessing = false; // Local loading state for this tile

  Future<void> _handleMarkAsPending() async {
    if (_isProcessing) return; // Prevent multiple clicks while processing

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onMarkItemAsPending(widget.item);
    } catch (e) {
      // Error handling for the operation itself is done in the parent's method,
      // but you could show a local error if needed.
      print("Error occurred in tile: $e");
    } finally {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the button should be enabled based on item properties
    bool canMarkPending = widget.item.quantity > 0 && !_isProcessing;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null ?
                             loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                    ));
                  },
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
        ),
        title: Text('${widget.item.brand} - ${widget.item.category}'),
        subtitle: Text(
          'On Shelf: ${widget.item.quantity} | Price: \$${widget.item.price.toStringAsFixed(2)}'
        ),
        isThreeLine: false,
        trailing: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.shopping_cart_checkout_outlined, color: Colors.blueAccent),
                tooltip: 'Move 1 to Pending Sale',
                onPressed: canMarkPending ? _handleMarkAsPending : null,
              ),
      ),
    );
  }
}