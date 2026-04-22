import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class CustomRadioButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T?>? onChanged;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged?.call(value),
      child: Container(
        padding: const EdgeInsets.symmetric(),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryFrances
                      : AppColors.greyBordes,
                  width: isSelected ? 7 : 2,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            Text(
              label,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
          ],
        ),
      ),
    );
  }
}
