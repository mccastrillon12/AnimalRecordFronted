import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

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
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final String? errorText;

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
    this.maxLength,
    this.inputFormatters,
    this.onEditingComplete,
    this.textInputAction,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: AppBorders.small(),
      borderSide: const BorderSide(color: AppColors.greyMedio, width: 1.0),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: AppBorders.small(),
      borderSide: const BorderSide(color: AppColors.error, width: 1.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with consistent spacing pattern
        if (label.isNotEmpty)
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: (labelStyle ?? AppTypography.body6).copyWith(
                  color: AppColors.greyNegroV2,
                ),
              ),
            ),
          ),

        if (label.isNotEmpty)
          const SizedBox(height: AppSpacing.inputTopPadding),

        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SizedBox(
            height: AppSpacing.inputHeight,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText ?? isPassword,
              keyboardType: keyboardType,
              validator: validator,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              onEditingComplete: onEditingComplete,
              textInputAction: textInputAction,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.body4,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                counterText: '', // Ocultar contador de caracteres
                hintText: hint,
                // Hide internal error text to use external custom error
                errorText: null,
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
                border: errorText != null
                    ? errorBorder
                    : (border ?? defaultBorder),
                enabledBorder: errorText != null
                    ? errorBorder
                    : (enabledBorder ?? defaultBorder),
                focusedBorder: errorText != null
                    ? errorBorder
                    : (focusedBorder ?? defaultBorder),
              ),
            ),
          ),
        ),

        // Error text displayed outside to align with label
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.body6.copyWith(
              color: AppColors.error,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
