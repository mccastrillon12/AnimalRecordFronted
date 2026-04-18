import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.errorText,
  });

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
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label
                          .replaceAll(' (Opcional)', '')
                          .replaceAll('(Opcional)', '')
                          .trim(),
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyNegroV2,
                      ),
                    ),
                    if (label.contains('(Opcional)'))
                      TextSpan(
                        text: ' (Opcional)',
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyBordes,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        if (label.isNotEmpty)
          const SizedBox(height: AppSpacing.inputTopPadding),

        SizedBox(
          height: AppSpacing.inputHeight,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.greyMedio,
              size: 24,
            ),
            dropdownColor: AppColors.white,
            style: AppTypography.body4.copyWith(
              color: AppColors.greyNegroV2,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              hintText: hint,
              hintStyle: AppTypography.body4.copyWith(
                color: AppColors.greyBordes,
              ),
              border: OutlineInputBorder(
                borderRadius: AppBorders.small(),
                borderSide: const BorderSide(
                  color: AppColors.greyBordes,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppBorders.small(),
                borderSide: const BorderSide(
                  color: AppColors.greyBordes,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppBorders.small(),
                borderSide: const BorderSide(
                  color: AppColors.greyBordes,
                  width: 1.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppBorders.small(),
                borderSide: const BorderSide(
                  color: AppColors.errorRojo,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.body5.copyWith(
              color: AppColors.error,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
