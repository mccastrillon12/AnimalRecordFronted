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
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  void _runAutoValidation() {
    if (!mounted) return;
    final text = widget.controller?.text.trim() ?? '';
    if (text.isEmpty) {
      if (_internalErrorText != null) {
        setState(() => _internalErrorText = null);
      }
      return;
    }

    String? error;
    final labelLow = widget.label.toLowerCase();

    if (widget.keyboardType == TextInputType.phone ||
        (labelLow.contains('celular') && !labelLow.contains('correo'))) {
      if (!_isValidPhone(text)) {
        error = 'Introduzca su número de celular en el formato XXX-XXX-XX-XX';
      }
    } else if (labelLow.contains('correo') && labelLow.contains('celular')) {
      if (RegExp(r'^[0-9+\-\s]+$').hasMatch(text)) {
        if (!_isValidPhone(text)) {
          error = 'Introduzca su número de celular en el formato XXX-XXX-XX-XX';
        }
      } else {
        if (!_isValidEmail(text)) {
          error = 'Introduzca una dirección de correo electrónico válida';
        }
      }
    } else if (widget.keyboardType == TextInputType.emailAddress ||
        labelLow.contains('correo')) {
      if (!_isValidEmail(text)) {
        error = 'Introduzca una dirección de correo electrónico válida';
      }
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
      borderSide: const BorderSide(color: AppColors.greyMedio, width: 1.0),
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
              child: Text(
                widget.label,
                style: (widget.labelStyle ?? AppTypography.body6).copyWith(
                  color: widget.labelStyle?.color ?? AppColors.greyNegroV2,
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
              style: AppTypography.body4,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: widget.hint,

                errorText: null,
                hintStyle:
                    widget.hintStyle ??
                    AppTypography.body4.copyWith(color: AppColors.greyMedio),
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
                    : (widget.border ?? defaultBorder),
                enabledBorder: currentErrorText != null
                    ? errorBorder
                    : (widget.enabledBorder ?? defaultBorder),
                focusedBorder: currentErrorText != null
                    ? errorBorder
                    : (widget.focusedBorder ?? defaultBorder),
              ),
            ),
          ),
        ),

        if (currentErrorText != null) ...[
          const SizedBox(height: 4),
          Text(
            currentErrorText,
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
