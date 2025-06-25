// File: lib/helpers/ui_helpers.dart
// Mục đích: Chứa các hàm trợ giúp về giao diện người dùng, có thể tái sử dụng.

import 'package:flutter/material.dart';

/// Hiển thị một SnackBar tùy chỉnh ở góc trên bên trái màn hình.
void showTopSnackBar(BuildContext context, String message, {bool isError = false}) {
  // Xóa bỏ các SnackBar cũ đang hiển thị để tránh xếp chồng.
  ScaffoldMessenger.of(context).clearSnackBars();
  
  // Hiển thị SnackBar mới.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      // --- UPDATE: Customization for transparent look ---
      backgroundColor: isError 
          ? Colors.redAccent.withOpacity(0.5) 
          : Colors.black.withOpacity(0.5),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Vị trí ở góc trên bên trái
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100, // Đẩy SnackBar lên trên cùng
        right: MediaQuery.of(context).size.width > 350 ? MediaQuery.of(context).size.width - 320 : 30, // Đẩy sang trái
        left: 16,
      ),
    ),
  );
}
