
// File: lib/models/incoming_order_model.dart
// Mục đích: Định nghĩa cấu trúc dữ liệu cho một đơn hàng mới từ khách hàng.

import 'package:cloud_firestore/cloud_firestore.dart';

class IncomingOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String shippingMethod; // 'COD' or 'Chuyển khoản'
  final List<Map<String, dynamic>> items; // List of items in the order
  final double orderTotalValue;
  final double amountToPay; // Amount to be paid upfront
  final Timestamp orderTimestamp;

  IncomingOrder({
    required this.id,
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
    return IncomingOrder(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      shippingMethod: data['shippingMethod'] ?? 'Unknown',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      orderTotalValue: (data['orderTotalValue'] as num?)?.toDouble() ?? 0.0,
      amountToPay: (data['amountToPay'] as num?)?.toDouble() ?? 0.0,
      orderTimestamp: data['orderTimestamp'] ?? Timestamp.now(),
    );
  }
}
