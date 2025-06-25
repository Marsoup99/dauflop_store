// File: lib/screens/incoming_orders_screen.dart
// Mục đích: Trang hiển thị danh sách các đơn hàng mới cần duyệt.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../localizations/app_localizations.dart';
import '../models/incoming_order_model.dart';
import '../widgets/incoming_order_tile.dart';

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {

  Future<void> _approveOrder(IncomingOrder order) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // --- FIX: Decrement stock when approving the order ---
      for (var itemMap in order.items) {
        final itemRef = firestore.collection('items').doc(itemMap['id']);
        final quantityToDecrement = itemMap['quantity'] as int;
        
        // 1. Decrement stock
        batch.update(itemRef, {'quantity': FieldValue.increment(-quantityToDecrement)});
        
        // 2. Create a new pending sale item
        final pendingSaleRef = firestore.collection('pending_sales').doc();
        final pendingSaleData = {
          'itemId': itemMap['id'],
          'itemName': '${itemMap['brand']} - ${itemMap['category']}',
          'itemColor': itemMap['color'],
          'imageUrl': itemMap['imageUrl'],
          'quantityPending': quantityToDecrement,
          'buyInPriceAtPending': itemMap['buyInPrice'],
          'sellPriceAtPending': itemMap['price'],
          'pendingTimestamp': Timestamp.now(),
          'customerName': order.customerName, 
          'customerPhone': order.customerPhone,
        };
        batch.set(pendingSaleRef, pendingSaleData);
      }

      // 3. Delete the incoming order
      final incomingOrderRef = firestore.collection('incoming_orders').doc(order.id);
      batch.delete(incomingOrderRef);
    
      await batch.commit();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt và chuyển đơn hàng sang mục chờ xử lý.'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi duyệt đơn hàng: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showOrderDetails(IncomingOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chi tiết đơn hàng - ${order.customerName}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('SĐT: ${order.customerPhone}'),
                Text('Địa chỉ: ${order.customerAddress}'),
                const Divider(),
                Text('Phương thức: ${order.shippingMethod}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Tổng giá trị: ${order.orderTotalValue.toInt()} cá'),
                Text('Cần thanh toán trước: ${order.amountToPay.toInt()} cá'),
                const Divider(),
                const Text('Sản phẩm đã đặt:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Text('- ${item['brand']} (${item['color']}) x${item['quantity']}')).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Duyệt Đơn'),
              onPressed: () {
                Navigator.of(context).pop();
                _approveOrder(order);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('incoming_orders')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('incoming_orders').orderBy('orderTimestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có đơn hàng mới nào.'));
          }

          final orders = snapshot.data!.docs.map((doc) => IncomingOrder.fromFirestore(doc)).toList();
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return IncomingOrderTile(
                order: order,
                onTap: () => _showOrderDetails(order),
              );
            },
          );
        },
      ),
    );
  }
}
