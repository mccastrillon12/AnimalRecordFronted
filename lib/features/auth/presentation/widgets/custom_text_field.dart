import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final Color? borderColor;
  final bool? obscureText;
  final VoidCallback? onToggleVisibility;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.labelStyle,
    this.hintStyle,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.borderColor,
    this.obscureText,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.greyMedio, width: 1.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.labelHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: labelStyle ?? AppTypography.body6),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.inputTopPadding),
          child: SizedBox(
            height: AppSpacing.inputHeight,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText ?? isPassword,
              keyboardType: keyboardType,
              validator: validator,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.body4,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                hintText: hint,
                hintStyle:
                    hintStyle ??
                    AppTypography.body4.copyWith(color: AppColors.greyMedio),
                prefixIcon: prefixIcon,
                suffixIcon:
                    suffixIcon ??
                    (isPassword
                        ? IconButton(
                            icon: Icon(
                              (obscureText ?? true)
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.greyMedio,
                              size: 20,
                            ),
                            onPressed: onToggleVisibility,
                          )
                        : null),
                border: border ?? defaultBorder,
                enabledBorder: enabledBorder ?? defaultBorder,
                focusedBorder: focusedBorder ?? defaultBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
