// File: lib/models/incoming_order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IncomingOrder {
  final String id;
  final String shortOrderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String shippingMethod;
  final List<Map<String, dynamic>> items;
  final double orderTotalValue;
  final double amountToPay;
  final Timestamp orderTimestamp;

  IncomingOrder({
    required this.id,
    required this.shortOrderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.shippingMethod,
    required this.items,
    required this.orderTotalValue,
    required this.amountToPay,
    required this.orderTimestamp,
  });

  factory IncomingOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // --- FIX: Safely parse the list of items to prevent type errors ---
    List<Map<String, dynamic>> itemsList = [];
    if (data['items'] != null && data['items'] is List) {
      // Manually iterate and cast each item in the list
      for (var item in (data['items'] as List)) {
        if (item is Map) {
          // Cast the map to the correct type to ensure type safety
          itemsList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return IncomingOrder(
      id: doc.id,
      shortOrderId: data['shortOrderId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      shippingMethod: data['shippingMethod'] ?? 'Unknown',
      items: itemsList, // Use the safely parsed list
      orderTotalValue: (data['orderTotalValue'] as num?)?.toDouble() ?? 0.0,
      amountToPay: (data['amountToPay'] as num?)?.toDouble() ?? 0.0,
      orderTimestamp: data['orderTimestamp'] ?? Timestamp.now(),
    );
  }
}
