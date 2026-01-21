import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'country_dropdown.dart';

class PhoneInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isOptional;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const PhoneInputField({
    super.key,
    required this.label,
    required this.controller,
    this.isOptional = false,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector using reusable component
        CountryDropdown(
          label: 'País',
          value: 'COP',
          countries: CountryOption.onlyColombia,
          onChanged: null, // Only Colombia for now
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
                hint: '(+57) 310 123 45 67',
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
