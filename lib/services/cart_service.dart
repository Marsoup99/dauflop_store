// File: lib/services/cart_service.dart
// Mục đích: Quản lý toàn bộ logic của giỏ hàng (thêm, xóa, cập nhật).

import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/item_model.dart';

class CartService {
  // Sử dụng mẫu Singleton để chỉ có một giỏ hàng duy nhất trong toàn bộ ứng dụng.
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // ValueNotifier sẽ tự động thông báo cho giao diện khi giỏ hàng thay đổi.
  final ValueNotifier<List<CartItem>> cart = ValueNotifier<List<CartItem>>([]);

  // --- UPDATE: addToCart now returns a boolean indicating success ---
  bool addToCart(Item item) {
    // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa.
    for (var cartItem in cart.value) {
      if (cartItem.item.id == item.id) {
        // --- ADDED: Check if adding one more would exceed stock ---
        if (cartItem.quantity < item.quantity) {
          cartItem.quantity++;
          cart.notifyListeners();
          return true; // Success
        } else {
          return false; // Failure, stock limit reached
        }
      }
    }
    // Nếu chưa có, thêm sản phẩm mới vào giỏ hàng nếu còn hàng.
    if (item.quantity > 0) {
      cart.value.add(CartItem(item: item));
      cart.notifyListeners();
      return true; // Success
    }
    return false; // Failure, item is out of stock from the start
  }

  void removeFromCart(String itemId) {
    cart.value.removeWhere((cartItem) => cartItem.item.id == itemId);
    cart.notifyListeners();
  }

  // --- UPDATE: updateQuantity now checks against stock ---
  void updateQuantity(String itemId, int newQuantity) {
    for (var cartItem in cart.value) {
      if (cartItem.item.id == itemId) {
        if (newQuantity <= 0) {
          removeFromCart(itemId);
        } else if (newQuantity <= cartItem.item.quantity) {
          // Only update if new quantity does not exceed stock
          cartItem.quantity = newQuantity;
        }
        // If newQuantity > stock, do nothing, preventing the increase.
        cart.notifyListeners();
        return;
      }
    }
  }

  // Phương thức để tính tổng số sản phẩm trong giỏ hàng.
  int get totalItems {
    return cart.value.fold(0, (sum, item) => sum + item.quantity);
  }

  // Phương thức để tính tổng tiền của giỏ hàng.
  double get totalPrice {
    return cart.value.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}
