import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

// --- UPDATE: Converted to a StatefulWidget to manage a loading state ---
class VietQRDisplayDialog extends StatefulWidget {
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
  State<VietQRDisplayDialog> createState() => _VietQRDisplayDialogState();
}

class _VietQRDisplayDialogState extends State<VietQRDisplayDialog> {
  bool _isImageReady = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quét mã hoặc mở ứng dụng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sử dụng ứng dụng ngân hàng để quét mã, hoặc nhấn nút bên dưới để mở ứng dụng.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 350,
              height: 350,
              // --- UPDATE: Use a Stack to overlay the image on the loading indicator ---
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // This is the loading indicator, always present initially
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Đang tạo mã QR...")
                        ],
                      ),
                    ),
                  ),
                  // The actual image, which will fade in on top
                  Image.network(
                    widget.qrDataURL,
                    fit: BoxFit.contain,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                       // This logic makes the image fade in smoothly once it's loaded.
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Không thể tải mã QR.\nVui lòng thử lại.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const Divider(height: 24),
            ListTile(
              title: const Text('Số tiền cần chuyển'),
              subtitle: Text('${widget.amount} cá', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryPink)),
            ),
            ListTile(
              title: const Text('Nội dung chuyển khoản'),
              subtitle: Text(widget.orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.orderId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã đơn hàng!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Hủy đơn'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Đã chuyển tiền'),
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
