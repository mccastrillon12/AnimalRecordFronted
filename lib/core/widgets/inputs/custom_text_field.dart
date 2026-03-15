import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
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
  final bool? enabled;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

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
    this.prefixText,
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
    this.enabled,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  String? _internalErrorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _runAutoValidation() {
    if (!mounted) return;
    final text = widget.controller?.text.trim() ?? '';

    String? error;
    if (widget.validator != null) {
      error = widget.validator!(text);
    }

    if (_internalErrorText != error) {
      setState(() => _internalErrorText = error);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _runAutoValidation();
    }
  }

  void _onChanged(String val) {
    if (_internalErrorText != null) {
      _runAutoValidation();
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), _runAutoValidation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: AppBorders.small(),
      borderSide: const BorderSide(color: AppColors.greyBordes, width: 1.0),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: AppBorders.small(),
      borderSide: const BorderSide(color: AppColors.error, width: 1.0),
    );

    final currentErrorText = widget.errorText ?? _internalErrorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.label
                          .replaceAll(' (Opcional)', '')
                          .replaceAll('(Opcional)', '')
                          .trim(),
                      style: (widget.labelStyle ?? AppTypography.body6)
                          .copyWith(
                            color:
                                widget.labelStyle?.color ??
                                AppColors.greyNegroV2,
                          ),
                    ),
                    if (widget.label.contains('(Opcional)'))
                      TextSpan(
                        text: ' (Opcional)',
                        style: (widget.labelStyle ?? AppTypography.body6)
                            .copyWith(color: AppColors.greyBordes),
                      ),
                  ],
                ),
              ),
            ),
          ),

        if (widget.label.isNotEmpty)
          const SizedBox(height: AppSpacing.inputTopPadding),

        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SizedBox(
            height: AppSpacing.inputHeight,
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: widget.obscureText ?? widget.isPassword,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: _onChanged,
              maxLength: widget.maxLength ?? (widget.isPassword ? 20 : 50),
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              inputFormatters: widget.inputFormatters,
              onFieldSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
              textInputAction: widget.textInputAction,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.body4.copyWith(
                color: (widget.enabled ?? true)
                    ? AppColors.greyNegroV2
                    : const Color(0xFF2E3949).withOpacity(0.3),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: (widget.enabled ?? true)
                    ? AppColors.white
                    : const Color(0xFFF5F6FA),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: (widget.enabled ?? true) ? widget.hint : null,

                errorText: null,
                hintStyle:
                    widget.hintStyle ??
                    AppTypography.body4.copyWith(
                      color: AppColors.greyDelineante,
                    ),
                prefixIcon: widget.prefixIcon,

                prefix: widget.prefixText != null
                    ? Text(
                        '${widget.prefixText} ',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      )
                    : null,
                suffixIcon:
                    widget.suffixIcon ??
                    (widget.isPassword
                        ? IconButton(
                            icon: Image.asset(
                              (widget.obscureText ?? true)
                                  ? 'assets/icons/vuesax-bold-eye.png'
                                  : 'assets/icons/vuesax-bold-eye-slash.png',
                              width: 20,
                              height: 20,
                              color: AppColors.greyMedio,
                            ),
                            onPressed: widget.onToggleVisibility,
                          )
                        : null),
                border: currentErrorText != null
                    ? errorBorder
                    : (widget.enabled ?? true)
                    ? (widget.border ?? defaultBorder)
                    : OutlineInputBorder(
                        borderRadius: AppBorders.small(),
                        borderSide: const BorderSide(
                          color: Color(0xFFE8E9EC),
                          width: 1.0,
                        ),
                      ),
                enabledBorder: currentErrorText != null
                    ? errorBorder
                    : (widget.enabledBorder ?? defaultBorder),
                focusedBorder: currentErrorText != null
                    ? errorBorder
                    : (widget.focusedBorder ?? defaultBorder),
                disabledBorder: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(
                    color: Color(0xFFE8E9EC),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),

        if (currentErrorText != null) ...[
          const SizedBox(height: 4),
          Text(
            currentErrorText,
            style: AppTypography.body5.copyWith(
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
