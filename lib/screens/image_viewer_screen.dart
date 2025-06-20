import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // Layer 1: Full-screen gesture detector for the background
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // Layer 2: The interactive image, centered
          Center(
            child: Hero(
              tag: heroTag,
              // The InteractiveViewer will capture gestures made on the image,
              // preventing them from reaching the background detector.
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error_outline, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
          // Layer 3: The close button, always on top
          Positioned(
            top: 40,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
