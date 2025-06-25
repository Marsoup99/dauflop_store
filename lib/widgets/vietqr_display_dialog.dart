
// File: lib/widgets/vietqr_display_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class VietQRDisplayDialog extends StatelessWidget {
  final String qrDataURL;
  final int amount;
  final String orderId;

  const VietQRDisplayDialog({
    super.key,
    required this.qrDataURL,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quét mã để thanh toán'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sử dụng ứng dụng ngân hàng của bạn để quét mã QR bên dưới.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Display the QR Code image from the URL
            SizedBox(
              width: 250,
              height: 250,
              child: Image.network(
                qrDataURL,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Không thể tải mã QR.\nVui lòng kiểm tra lại thông tin ngân hàng trong code.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Display payment details
            ListTile(
              title: const Text('Số tiền cần chuyển'),
              subtitle: Text(
                '$amount cá',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPink,
                    ),
              ),
            ),
            ListTile(
              title: const Text('Nội dung chuyển khoản'),
              subtitle: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: orderId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã đơn hàng!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Đóng'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
