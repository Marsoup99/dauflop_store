import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';
import '../theme/app_theme.dart';
import '../helpers/ui_helpers.dart';
import '../widgets/vietqr_display_dialog.dart';

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

  // --- UPDATE: Default state is now collapsed ---
  bool _isSummaryVisible = false;

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
    
    double amountToPay = _selectedPaymentMethod == PaymentMethod.cod ? codDeposit : orderTotalValue;
    final String shortOrderId = (100000 + Random().nextInt(900000)).toString();

    const String bankId = "970415"; 
    const String accountNumber = "0368267654"; 
    const String accountName = "TRUONG THI HUYNH NHI";

    final int amountVND = (amountToPay * 1000).toInt();
    final String description = Uri.encodeComponent(shortOrderId);
    final String name = Uri.encodeComponent(accountName);

    final String qrDataURL = 'https://img.vietqr.io/image/$bankId-$accountNumber-compact2.png?amount=$amountVND&addInfo=$description&accountName=$name';
    final String paymentUrl = 'https://api.vietqr.io/v2/pay?to=$accountNumber&amount=$amountVND&memo=$description&acqId=$bankId';
    
    final bool? paymentConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VietQRDisplayDialog(
        qrDataURL: qrDataURL,
        amount: amountToPay.toInt(),
        orderId: shortOrderId,
      ),
    );

    if (paymentConfirmed != true) {
      showTopSnackBar(context, 'Đơn hàng đã được hủy.', isError: true);
      setState(() => _isProcessing = false);
      return; 
    }

    try {
      final String paymentMethodString = _selectedPaymentMethod == PaymentMethod.cod ? "COD (Chờ cọc)" : "VietQR";
      final itemsList = _cartService.cart.value.map((cartItem) {
        return {'id': cartItem.item.id, 'brand': cartItem.item.brand, 'category': cartItem.item.category, 'color': cartItem.item.color, 'price': cartItem.item.price, 'buyInPrice': cartItem.item.buyInPrice, 'imageUrl': cartItem.item.imageUrl, 'quantity': cartItem.quantity};
      }).toList();

      final newOrderRef = FirebaseFirestore.instance.collection('incoming_orders').doc();
      final orderData = {
        'orderId': newOrderRef.id, 
        'shortOrderId': shortOrderId,
        'customerName': _nameController.text.trim(), 
        'customerPhone': _phoneController.text.trim(), 
        'customerAddress': _addressController.text.trim(),
        'shippingMethod': paymentMethodString, 
        'items': itemsList, 
        'orderTotalValue': orderTotalValue, 
        'amountToPay': amountToPay,
        'orderTimestamp': FieldValue.serverTimestamp(), 
        'paymentStatus': 'unpaid',
      };
      
      await newOrderRef.set(orderData);

      _cartService.cart.value = [];
      if(mounted) {
         showTopSnackBar(context, 'Đặt hàng thành công! Shop sẽ liên hệ với bạn.');
         Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Lỗi gửi đơn hàng: $e', isError: true);
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
          String buttonLabel = "Xác nhận";
          
          switch (_selectedPaymentMethod) {
            case PaymentMethod.cod:
              paymentLabel = "Số tiền cần cọc:";
              amountToPay = codDeposit;
              buttonLabel = "Xác nhận và Cọc tiền";
              break;
            case PaymentMethod.vietQR:
              paymentLabel = "Thanh toán ngay:";
              amountToPay = orderTotal;
              buttonLabel = "Xác nhận và Quét mã QR";
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
                            // --- FIX: Added phone number validation ---
                            TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(labelText: 'Số Điện Thoại'),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập số điện thoại';
                                  }
                                  // Regular expression for a typical 10-digit Vietnamese phone number starting with 0
                                  final phoneRegExp = RegExp(r'^0[0-9]{9}$');
                                  if (!phoneRegExp.hasMatch(value)) {
                                    return 'Số điện thoại không hợp lệ (gồm 10 số, bắt đầu bằng 0)';
                                  }
                                  return null;
                                },
                            ),
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
                        title: const Text('Giao hàng (COD)'),
                        subtitle: const Text('Cọc trước 30k qua VietQR, phần còn lại thanh toán khi nhận hàng.'),
                        value: PaymentMethod.cod,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (PaymentMethod? value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                      RadioListTile<PaymentMethod>(
                        title: const Text('Chuyển khoản VietQR'),
                        subtitle: const Text('Thanh toán toàn bộ giá trị đơn hàng qua mã QR.'),
                        value: PaymentMethod.vietQR,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (PaymentMethod? value) => setState(() => _selectedPaymentMethod = value!),
                      ),
                    ],
                  ),
                ),
              ),
              // --- FIX: Collapsible Checkout Summary Section ---
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 10)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Collapsible Details Section
                    Visibility(
                      visible: _isSummaryVisible,
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tiền hàng:', style: Theme.of(context).textTheme.bodyLarge), Text('${itemsTotal.toInt()} cá', style: Theme.of(context).textTheme.bodyLarge)]),
                          Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Phí ship:', style: Theme.of(context).textTheme.bodyLarge), Text('${shippingFee.toInt()} cá', style: Theme.of(context).textTheme.bodyLarge)])),
                          const Divider(height: 16),
                        ],
                      ),
                    ),
                    // Always Visible Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(paymentLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(
                              '${amountToPay.toInt()} cá',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
                            ),
                            // Toggle Button
                            IconButton(
                              icon: Icon(_isSummaryVisible ? Icons.expand_less : Icons.expand_more),
                              tooltip: 'Hiện/Ẩn chi tiết',
                              onPressed: () => setState(() => _isSummaryVisible = !_isSummaryVisible),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isProcessing ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                        label: Text(_isProcessing ? 'Đang xử lý...' : buttonLabel),
                        onPressed: _isProcessing ? null : _submitOrder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}