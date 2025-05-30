import 'package:flutter/material.dart';
import '../../models/pending_sale_model.dart'; // Your PendingSale model

class PendingSaleItemTile extends StatefulWidget {
  final PendingSale pendingSale;
  final Future<void> Function(PendingSale pendingSale) onConfirm;
  final Future<void> Function(PendingSale pendingSale) onCancel;

  const PendingSaleItemTile({
    super.key,
    required this.pendingSale,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<PendingSaleItemTile> createState() => _PendingSaleItemTileState();
}

class _PendingSaleItemTileState extends State<PendingSaleItemTile> {
  bool _isProcessing = false; // Local loading state for this tile

  Future<void> _handleConfirmSale() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onConfirm(widget.pendingSale);
    } catch (e) {
      // Error already handled in the parent's method (shows SnackBar)
      print("Error during confirm from tile: $e");
    } finally {
      // If the widget is still mounted after the async operation
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCancelSale() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onCancel(widget.pendingSale);
    } catch (e) {
      // Error already handled in the parent's method
      print("Error during cancel from tile: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: widget.pendingSale.imageUrl != null && widget.pendingSale.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.pendingSale.imageUrl!,
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
        title: Text(widget.pendingSale.itemName),
        subtitle: Text('Qty Pending: ${widget.pendingSale.quantityPending}\nSell Price: \$${widget.pendingSale.sellPriceAtPending.toStringAsFixed(2)}'),
        isThreeLine: true,
        trailing: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Cancel Sale',
                    onPressed: _handleCancelSale,
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: 'Confirm Sale',
                    onPressed: _handleConfirmSale,
                  ),
                ],
              ),
      ),
    );
  }
}