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
  final TextEditingController controller;
  final List<CountryEntity> countries;
  final String? selectedCountryId;
  final ValueChanged<String?>? onCountryChanged;
  final bool isOptional;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  const PhoneInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.countries,
    this.selectedCountryId,
    this.onCountryChanged,
    this.isOptional = false,
    this.maxLength,
    this.inputFormatters,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector using reusable component
        if (countries.isNotEmpty)
          CountryDropdown(
            label: 'País',
            value:
                selectedCountryId ??
                (countries.isNotEmpty ? countries.first.id : ''),
            countries: countries,
            onChanged: onCountryChanged,
            showIsoCodeAsValue: true,
            enabled: true,
          ),

        const SizedBox(width: AppSpacing.xs),

        // Phone number field
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: AppTypography.body6),
                ),
              ),

              const SizedBox(height: AppSpacing.inputTopPadding),

              CustomTextField(
                label: '',
                hint: '310 123 45 67',
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                errorText: errorText,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Text(
                    '(${countries.cast<CountryEntity>().firstWhere((c) => c.id == (selectedCountryId ?? countries.first.id), orElse: () => countries.first).dialCode})',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
