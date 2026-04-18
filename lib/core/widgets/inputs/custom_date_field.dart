import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomDateField extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;

  const CustomDateField({
    super.key,
    required this.label,
    this.hint = 'month dd, yyyy',
    this.value,
    this.onChanged,
    this.enabled = true,
  });

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryFrances,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.greyTextos,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: AppTypography.body6.copyWith(
                  color: AppColors.greyNegroV2,
                ),
              ),
            ),
          ),

        if (label.isNotEmpty)
          const SizedBox(height: AppSpacing.inputTopPadding),

        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            height: AppSpacing.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? AppColors.white : const Color(0xFFF5F6FA),
              borderRadius: AppBorders.small(),
              border: Border.all(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value!) : hint,
                    style: AppTypography.body4.copyWith(
                      color: value != null
                          ? AppColors.greyNegroV2
                          : AppColors.greyBordes,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.greyMedio,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
