import 'package:cloud_firestore/cloud_firestore.dart';

class PendingSale {
  final String id; // Firestore document ID of the pending sale
  final String itemId;
  final String itemName;
  final String? itemColor;
  final String? imageUrl;
  final int quantityPending;
  final double buyInPriceAtPending;
  final double sellPriceAtPending;
  final Timestamp pendingTimestamp;

  PendingSale({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.itemColor,
    this.imageUrl,
    required this.quantityPending,
    required this.buyInPriceAtPending,
    required this.sellPriceAtPending,
    required this.pendingTimestamp,
  });

  // Factory constructor to create a PendingSale object from a Firestore document
  factory PendingSale.fromMap(Map<String, dynamic> map, String documentId) {
    return PendingSale(
      id: documentId,
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? 'Unknown Item',
      itemColor: map['itemColor'] as String?,
      imageUrl: map['imageUrl'] as String?,
      quantityPending: map['quantityPending'] as int? ?? 0,
      buyInPriceAtPending: (map['buyInPriceAtPending'] as num?)?.toDouble() ?? 0.0,
      sellPriceAtPending: (map['sellPriceAtPending'] as num?)?.toDouble() ?? 0.0,
      pendingTimestamp: map['pendingTimestamp'] as Timestamp? ?? Timestamp.now(), // Provide a default if null
    );
  }

  // We don't necessarily need a toMap() for this model if we are only reading it
  // and then creating sales_transactions or updating items based on its data.
  // The _markItemAsPending method currently creates the map directly.
  // If you wanted to update pending_sales docs, then a toMap() would be useful.
}