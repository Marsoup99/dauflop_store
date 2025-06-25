// File: lib/widgets/incoming_order_tile.dart
// Mục đích: Widget hiển thị tóm tắt mỗi đơn hàng mới trong danh sách.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incoming_order_model.dart';

class IncomingOrderTile extends StatelessWidget {
  final IncomingOrder order;
  final VoidCallback onTap;

  const IncomingOrderTile({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = order.items.fold(0, (sum, item) => sum + (item['quantity'] as int));
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(totalItems.toString()),
        ),
        title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Đặt lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderTimestamp.toDate())}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${order.orderTotalValue.toInt()} cá', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order.shippingMethod, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
