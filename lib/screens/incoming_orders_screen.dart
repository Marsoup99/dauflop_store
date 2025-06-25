import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localizations/app_localizations.dart';
import '../models/incoming_order_model.dart';
import '../widgets/incoming_order_tile.dart';

const bool kDemoMode = false;

class IncomingOrdersScreen extends StatefulWidget {
  const IncomingOrdersScreen({super.key});

  @override
  State<IncomingOrdersScreen> createState() => _IncomingOrdersScreenState();
}

class _IncomingOrdersScreenState extends State<IncomingOrdersScreen> {

  List<IncomingOrder> _demoOrders = [];

  @override
  void initState() {
    super.initState();
    if (kDemoMode) {
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    _demoOrders = [
      IncomingOrder(
        id: 'demo_id_1',
        shortOrderId: '123456',
        customerName: 'Nguyễn Văn An',
        customerPhone: '0909123456',
        customerAddress: '123 Đường ABC, Phường X, Quận Y, TP. HCM',
        shippingMethod: 'COD (Chờ cọc)',
        items: [{'brand': 'Son Môi', 'color': 'Đỏ cam', 'quantity': 1}],
        orderTotalValue: 150.0,
        amountToPay: 30.0,
        orderTimestamp: Timestamp.now(),
      ),
      IncomingOrder(
        id: 'demo_id_2',
        shortOrderId: '789012',
        customerName: 'Trần Thị Bình',
        customerPhone: '0987654321',
        customerAddress: '456 Đường DEF, Phường Z, Quận W, Hà Nội',
        shippingMethod: 'VietQR',
        items: [
          {'brand': 'Phấn Má', 'color': 'Hồng đào', 'quantity': 2},
          {'brand': 'Kẻ Mắt', 'color': 'Nâu', 'quantity': 1},
        ],
        orderTotalValue: 355.0,
        amountToPay: 355.0,
        orderTimestamp: Timestamp.now(),
      ),
    ];
  }


  Future<void> _approveOrder(IncomingOrder order) async {
    if (kDemoMode) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[DEMO] Đã duyệt đơn hàng.'), backgroundColor: Colors.blue)
        );
        setState(() {
          _demoOrders.removeWhere((o) => o.id == order.id);
        });
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      await firestore.runTransaction((transaction) async {
        for (var itemMap in order.items) {
          final itemRef = firestore.collection('items').doc(itemMap['id']);
          final itemDoc = await transaction.get(itemRef);

          if (!itemDoc.exists) {
            throw Exception('Sản phẩm "${itemMap['brand']}" không còn tồn tại trong kho.');
          }

          final currentQuantity = (itemDoc.data()! as Map<String, dynamic>)['quantity'] as int;
          final quantityToDecrement = itemMap['quantity'] as int;

          if (currentQuantity < quantityToDecrement) {
            throw Exception('Không đủ hàng cho sản phẩm "${itemMap['brand']}". Trong kho còn $currentQuantity, đơn hàng cần $quantityToDecrement.');
          }
        }

        for (var itemMap in order.items) {
          final itemRef = firestore.collection('items').doc(itemMap['id']);
          final quantityToDecrement = itemMap['quantity'] as int;
          
          transaction.update(itemRef, {'quantity': FieldValue.increment(-quantityToDecrement)});
          
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
          transaction.set(pendingSaleRef, pendingSaleData);
        }

        final incomingOrderRef = firestore.collection('incoming_orders').doc(order.id);
        transaction.delete(incomingOrderRef);
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt và chuyển đơn hàng sang mục chờ xử lý.'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi duyệt đơn hàng: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5))
        );
      }
    }
  }

  Future<void> _cancelOrder(IncomingOrder order) async {
    if (kDemoMode) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('[DEMO] Đã hủy đơn hàng.'), backgroundColor: Colors.orange)
        );
         setState(() {
          _demoOrders.removeWhere((o) => o.id == order.id);
        });
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('incoming_orders').doc(order.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công.'), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi hủy đơn hàng: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }


  void _showOrderDetails(IncomingOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chi tiết đơn hàng'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Text(order.customerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, size: 20),
                  title: Text(order.customerPhone),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    tooltip: 'Sao chép SĐT',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.customerPhone));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép số điện thoại!')));
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home_outlined, size: 20),
                  title: Text(order.customerAddress),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),
                Text('Thông tin thanh toán', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Phương thức: ${order.shippingMethod}'),
                 ListTile(
                  title: Text('Mã chuyển khoản: ${order.shortOrderId}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  trailing: IconButton(
                     icon: const Icon(Icons.copy_outlined, size: 20),
                     tooltip: 'Sao chép mã',
                     onPressed: () {
                       Clipboard.setData(ClipboardData(text: order.shortOrderId));
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã chuyển khoản!')));
                     },
                   ),
                ),
                Text('Tổng giá trị: ${order.orderTotalValue.toInt()} cá'),
                Text('Cần thanh toán trước: ${order.amountToPay.toInt()} cá', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                Text('Sản phẩm đã đặt:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 16),
                  child: Text('- ${item['brand']} (${item['color']}) x${item['quantity']}'),
                )).toList(),
              ],
            ),
          ),
          // --- FIX: Replaced Spacer with MainAxisAlignment ---
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hủy Đơn'),
              onPressed: () async {
                Navigator.of(context).pop();
                final bool? confirmCancel = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận hủy'),
                    content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Không'),
                      ),
                       FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Hủy Đơn'),
                      ),
                    ],
                  ),
                );

                if (confirmCancel == true) {
                   _cancelOrder(order);
                }
              },
            ),
            const SizedBox(width: 8), // Add some space
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
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

  Widget _buildContent(List<IncomingOrder> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('Không có đơn hàng mới nào.'));
    }
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
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.translate('incoming_orders')} ${kDemoMode ? "(DEMO)" : ""}'),
      ),
      body: kDemoMode
        ? _buildContent(_demoOrders)
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('incoming_orders').orderBy('orderTimestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final orders = snapshot.data!.docs.map((doc) => IncomingOrder.fromFirestore(doc)).toList();
              return _buildContent(orders);
            },
          ),
    );
  }
}
