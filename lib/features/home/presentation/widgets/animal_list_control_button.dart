import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AnimalListControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Key? buttonKey;

  const AnimalListControlButton({
    super.key,
    required this.child,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      child: Container(
        width: AppSpacing.iconSizeMedium,
        height: AppSpacing.iconSizeMedium,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.greyDelineante),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1925).withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
