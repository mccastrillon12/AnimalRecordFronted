import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animal_record/core/theme/app_colors.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0), // Full screen
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Semi-transparent black background
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
            ),
          ),
          
          // Image with InteractiveViewer
          InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 48),
              ),
            ),
          ),

          // Close Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
