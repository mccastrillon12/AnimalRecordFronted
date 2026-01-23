import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

/// A reusable card widget for displaying and selecting roles or options.
///
/// This widget displays a title and an image in a styled container with
/// a shadow effect. It's designed to be used in selection screens where
/// users need to choose between different options.
///
/// Example:
/// ```dart
/// SelectableRoleCard(
///   title: 'Veterinario',
///   imageAsset: 'assets/illustrations/Perfil_veterinario.png',
///   onTap: () => navigateToVeterinarianRegistration(),
/// )
/// ```
class SelectableRoleCard extends StatelessWidget {
  /// The title text to display on the card
  final String title;

  /// The asset path for the image to display
  final String imageAsset;

  /// Callback function to execute when the card is tapped
  final VoidCallback onTap;

  /// Optional custom height for the card. Defaults to 117
  final double height;

  /// Optional custom width for the image. Defaults to 120
  final double imageWidth;

  /// Optional custom height for the image. Defaults to 85.26
  final double imageHeight;

  const SelectableRoleCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.onTap,
    this.height = 117,
    this.imageWidth = 120,
    this.imageHeight = 85.26,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgHielo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyNegro.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 26),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(title, style: AppTypography.body3),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 24, top: 16, bottom: 16),
              child: Image.asset(
                imageAsset,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
