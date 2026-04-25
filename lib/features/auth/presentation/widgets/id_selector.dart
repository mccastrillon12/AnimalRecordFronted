import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';

class IdSelector extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? initialIdType;
  final ValueChanged<String>? onIdTypeChanged;
  final String? errorText;
  final bool hideErrorText;

  const IdSelector({
    super.key,
    this.initialValue,
    this.onChanged,
    this.controller,
    this.initialIdType,
    this.onIdTypeChanged,
    this.errorText,
    this.hideErrorText = false,
  });

  static const List<String> _idTypes = ['C.C.', 'C.E.', 'Pasaporte'];

  @override
  Widget build(BuildContext context) {
    final selectedType = initialIdType ?? 'C.C.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.labelHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Identificación', style: AppTypography.body6),
          ),
        ),
        const SizedBox(height: AppSpacing.inputTopPadding),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ID Type Dropdown (uses AppDropdown) ──────────────
            AppDropdown<String>(
              label: '',
              hint: 'Tipo',
              value: selectedType,
              items: _idTypes,
              itemAsString: (type) => type,
              onChanged: (value) {
                if (value != null) {
                  onIdTypeChanged?.call(value);
                }
              },
              width: selectedType == 'Pasaporte' ? 140 : 100,
              showClearOption: false,
              pushContent: false,
            ),

            const SizedBox(width: AppSpacing.xs),

            // ── ID Number Input ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: AppSpacing.inputHeight,
                    child: TextFormField(
                      controller: controller,
                      initialValue:
                          controller == null ? initialValue : null,
                      onChanged: onChanged,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                      ],
                      maxLength: 50,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      style: AppTypography.body4,
                      decoration: InputDecoration(
                        hintText: '1234567890',
                        hintStyle: AppTypography.body4.copyWith(
                          color: AppColors.greyBordes,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? AppColors.error
                                : AppColors.greyBordes,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? AppColors.error
                                : AppColors.greyBordes,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? AppColors.error
                                : AppColors.greyBordes,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (errorText != null && !hideErrorText) ...[
                    const SizedBox(height: 4),
                    Text(
                      errorText!,
                      style: AppTypography.body5.copyWith(
                        color: AppColors.error,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
