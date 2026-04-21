import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

/// A reusable list/menu item row with title, optional leading icon,
/// navigation arrow, and tap action.
///
/// Used in the animal detail screen for options like
/// "Información", "Historia clínica", "Carné de vacunas", etc.
class MenuItemRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showArrow;

  const MenuItemRow({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 327,
        height: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.greyDelineante,
              width: 0.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: AppColors.primaryFrances,
              ),
              const SizedBox(width: AppSpacing.s),
            ],

            Expanded(
              child: Text(
                title,
                style: AppTypography.body3.copyWith(
                  color: AppColors.greyNegro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.primaryFrances,
              ),
          ],
        ),
      ),
    );
  }
}
