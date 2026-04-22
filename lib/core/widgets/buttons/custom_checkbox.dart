import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryFrances : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppColors.primaryFrances : AppColors.greyBordes,
                width: 1,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }
}
