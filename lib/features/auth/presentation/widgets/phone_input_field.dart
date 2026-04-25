import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import 'package:flutter/services.dart';
import 'country_dropdown.dart';

class PhoneInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final List<CountryEntity> countries;
  final String? selectedCountryId;
  final ValueChanged<String?>? onCountryChanged;
  final bool isOptional;
  final int? maxLength;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final bool hideErrorText;
  final TextStyle? labelStyle;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PhoneInputField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    required this.countries,
    this.selectedCountryId,
    this.onCountryChanged,
    this.isOptional = false,
    this.focusNode,
    this.maxLength,
    this.inputFormatters,
    this.errorText,
    this.hideErrorText = false,
    this.labelStyle,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countries.isNotEmpty)
          CountryDropdown(
            label: 'País',
            labelStyle: labelStyle,
            value:
                selectedCountryId ??
                (countries.isNotEmpty ? countries.first.id : ''),
            countries: countries,
            onChanged: onCountryChanged,
            showIsoCodeAsValue: true,
            enabled: true,
            pushContent: false,
          ),

        const SizedBox(width: AppSpacing.xs),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          style: (labelStyle ?? AppTypography.body6).copyWith(
                            color: labelStyle?.color ?? AppColors.greyNegroV2,
                          ),
                        ),
                        if (label.contains('(Opcional)'))
                          TextSpan(
                            text: ' (Opcional)',
                            style: (labelStyle ?? AppTypography.body6).copyWith(
                              color: AppColors.greyBordes,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.inputTopPadding),

              CustomTextField(
                label: '',
                controller: controller,
                initialValue: initialValue,
                onChanged: onChanged,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: textInputAction ?? TextInputAction.done,
                onSubmitted: onSubmitted,
                maxLength: 15,
                inputFormatters: inputFormatters,
                errorText: errorText,
                hideErrorText: hideErrorText,
                prefixIcon: countries.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Text(
                          '(${countries.cast<CountryEntity>().firstWhere((c) => c.id == selectedCountryId, orElse: () => countries.first).dialCode})',
                          style: AppTypography.body4.copyWith(
                            color: AppColors.greyBordes,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
