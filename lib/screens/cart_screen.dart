import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';
import '../theme/app_theme.dart';
import '../helpers/ui_helpers.dart';
import '../widgets/vietqr_display_dialog.dart'; // --- NEW: Import the QR dialog ---

enum PaymentMethod { cod, vietQR }

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isProcessing = true);

    const double shippingFee = 15.0;
    const double codDeposit = 30.0;
    final double itemsTotal = _cartService.totalPrice;
    final double orderTotalValue = itemsTotal + shippingFee;
    
    String paymentMethodString = _selectedPaymentMethod == PaymentMethod.cod ? "COD" : "VietQR";
    double amountToPay = _selectedPaymentMethod == PaymentMethod.cod ? codDeposit : orderTotalValue;

    final itemsList = _cartService.cart.value.map((cartItem) {
      return {'id': cartItem.item.id, 'brand': cartItem.item.brand, 'category': cartItem.item.category, 'color': cartItem.item.color, 'price': cartItem.item.price, 'buyInPrice': cartItem.item.buyInPrice, 'imageUrl': cartItem.item.imageUrl, 'quantity': cartItem.quantity};
    }).toList();

    final newOrderRef = FirebaseFirestore.instance.collection('incoming_orders').doc();
    final orderData = {
      'orderId': newOrderRef.id, 'customerName': _nameController.text.trim(), 'customerPhone': _phoneController.text.trim(), 'customerAddress': _addressController.text.trim(),
      'shippingMethod': paymentMethodString, 'items': itemsList, 'orderTotalValue': orderTotalValue, 'amountToPay': amountToPay,
      'orderTimestamp': FieldValue.serverTimestamp(), 'paymentStatus': 'unpaid',
    };
    
    try {
        // --- FIX: Only create the order, DO NOT update stock ---
        await newOrderRef.set(orderData);
        
        if (_selectedPaymentMethod == PaymentMethod.vietQR) {
          const bankId = "970489"; // Techcombank BIN
          const accountNumber = "0368267654"; // Your account number
          
          final qrDataURL = 'https://img.vietqr.io/image/$bankId-$accountNumber-compact2.png?amount=${(amountToPay * 1000).toInt()}&addInfo=${newOrderRef.id}';
          await showDialog(
            context: context,
            builder: (context) => VietQRDisplayDialog(qrDataURL: qrDataURL, amount: (amountToPay).toInt(), orderId: newOrderRef.id),
          );
        }

        _cartService.cart.value = [];
        if(mounted) {
           showTopSnackBar(context, 'Đặt hàng thành công! Shop sẽ liên hệ với bạn.');
           Navigator.of(context).pop(); 
        }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Đã có lỗi xảy ra. Vui lòng thử lại.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double shippingFee = 15.0;
    const double codDeposit = 30.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ Hàng và Thanh Toán'),
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: _cartService.cart,
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty && !_isProcessing) {
            return const Center(
              child: Text('Giỏ hàng của bạn đang trống.', style: TextStyle(fontSize: 18, color: AppTheme.lightText)),
            );
          }
          
          final double itemsTotal = _cartService.totalPrice;
          final double orderTotal = itemsTotal + shippingFee;

          String paymentLabel = "Cần thanh toán:";
          double amountToPay = 0;
          switch (_selectedPaymentMethod) {
            case PaymentMethod.cod:
              paymentLabel = "Số tiền cần cọc:";
              amountToPay = codDeposit;
              break;
            case PaymentMethod.vietQR:
              paymentLabel = "Cần thanh toán:";
              amountToPay = orderTotal;
              break;
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Customer Info Form remains the same)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                           final cartItem = cartItems[index];
                           return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              leading: SizedBox(
                                width: 60, height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(cartItem.item.imageUrl ?? '', fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(cartItem.item.brand, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${cartItem.item.category} - Màu: ${cartItem.item.color}\n${cartItem.totalPrice.toInt()} cá',
                                style: const TextStyle(height: 1.4),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => _cartService.updateQuantity(cartItem.item.id!, cartItem.quantity - 1),
                                  ),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: cartItem.quantity < cartItem.item.quantity ? AppTheme.primaryPink : Colors.grey,
                                    ),
                                    onPressed: () {
                                      if (cartItem.quantity < cartItem.item.quantity) {
                                        _cartService.updateQuantity(cartItem.item.id!, cartItem.quantity + 1);
                                      } else {
                                        showTopSnackBar(context, 'Số lượng trong giỏ đã đạt tối đa.', isError: true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text('Thông Tin Giao Hàng', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Họ và Tên'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null),
                            const SizedBox(height: 12),
                            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Số Điện Thoại'), keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null),
                             const SizedBox(height: 12),
                            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng'), maxLines: 2, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      Text('Phương Thức Thanh Toán', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      RadioListTile<PaymentMethod>(
                        title: const Text('Thanh toán khi nhận hàng (COD)'),
                        subtitle: Text('Phí ship: ${shippingFee.toInt()}k. Cọc trước: ${codDeposit.toInt()}k.'),
                        value: PaymentMethod.cod,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (PaymentMethod? value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                      // --- REMOVED Bank Transfer, replaced with VietQR ---
                      RadioListTile<PaymentMethod>(
                        title: const Text('Chuyển khoản qua VietQR'),
                        subtitle: Text('Phí ship: ${shippingFee.toInt()}k. Vui lòng quét mã để chuyển khoản toàn bộ giá trị đơn hàng.'),
                        value: PaymentMethod.vietQR,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (PaymentMethod? value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 10)]),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tiền hàng:', style: Theme.of(context).textTheme.bodyLarge), Text('${itemsTotal.toInt()} cá', style: Theme.of(context).textTheme.bodyLarge)]),
                    Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Phí ship:', style: Theme.of(context).textTheme.bodyLarge), Text('${shippingFee.toInt()} cá', style: Theme.of(context).textTheme.bodyLarge)])),
                    const Divider(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tổng giá trị đơn:', style: Theme.of(context).textTheme.bodyLarge), Text('${orderTotal.toInt()} cá', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(paymentLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), Text('${amountToPay.toInt()} cá', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryPink, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isProcessing ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                        label: Text(_isProcessing ? 'Đang xử lý...' : 'Xác Nhận Đơn Hàng'),
                        onPressed: _isProcessing ? null : _submitOrder,
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
