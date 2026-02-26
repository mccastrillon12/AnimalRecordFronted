import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class SelectableRoleCard extends StatelessWidget {
  final String title;

  final String imageAsset;

  final VoidCallback onTap;

  final double height;

  final double imageWidth;

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
