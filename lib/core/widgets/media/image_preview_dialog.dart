import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animal_record/core/theme/app_colors.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final Uint8List? imageBytes;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    this.imageBytes,
  });

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
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          // Image with InteractiveViewer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: imageBytes != null && imageBytes!.isNotEmpty
                  ? Image.memory(
                      imageBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _errorPlaceholder(),
                    )
                  : imageUrl.startsWith('http') || imageUrl.startsWith('https')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => _errorPlaceholder(),
                    )
                  : Image.file(
                      File(imageUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _errorPlaceholder(),
                    ),
            ),
          ),

          // Close Button
          Positioned(
            top: 54,
            right: 24,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder() => const Center(
    child: Icon(Icons.broken_image, color: Colors.white, size: 48),
  );
}
