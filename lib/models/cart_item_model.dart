// File: lib/models/cart_item_model.dart
// Mục đích: Định nghĩa cấu trúc của một sản phẩm khi được thêm vào giỏ hàng.

import 'item_model.dart';

class CartItem {
  final Item item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get totalPrice => item.price * quantity;
}
