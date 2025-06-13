import 'package:flutter/material.dart';
import '../../localizations/app_localizations.dart'; // Import localization
import '../../models/pending_sale_model.dart';
import '../../theme/app_theme.dart';

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
  bool _isProcessing = false;

  Future<void> _handleAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context); // Get localization instance

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: SizedBox(
                width: 70,
                height: 70,
                child: widget.pendingSale.imageUrl != null && widget.pendingSale.imageUrl!.isNotEmpty
                    ? Image.network(widget.pendingSale.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40, color: AppTheme.lightText),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pendingSale.itemName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                   const SizedBox(height: 4),
                  Text(
                    '${loc.translate('quantity_pending')}: ${widget.pendingSale.quantityPending}',
                     style: Theme.of(context).textTheme.bodyMedium,
                  ),
                   const SizedBox(height: 4),
                   Text(
                    '\$${widget.pendingSale.sellPriceAtPending.toStringAsFixed(2)}',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.bold
                      ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isProcessing
              ? const SizedBox(width: 48, height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                      tooltip: loc.translate('dialog_cancel_button'), // Use translated tooltip
                      onPressed: () => _handleAction(() => widget.onCancel(widget.pendingSale)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      tooltip: loc.translate('confirm_button'), // Use translated tooltip
                      onPressed: () => _handleAction(() => widget.onConfirm(widget.pendingSale)),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
