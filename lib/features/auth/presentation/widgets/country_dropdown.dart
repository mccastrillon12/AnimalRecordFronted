import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class CountryDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?>? onChanged;
  final List<CountryOption> countries;

  const CountryDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(label, style: AppTypography.body6),

        const SizedBox(height: AppSpacing.inputTopPadding),

        // Dropdown container
        Container(
          height: AppSpacing.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greyMedio),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country.code,
                  child: Row(
                    children: [
                      Text(country.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(country.name, style: AppTypography.body4),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper class for country options
class CountryOption {
  final String code;
  final String name;
  final String flag;

  const CountryOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  // Predefined countries
  static const colombia = CountryOption(code: 'COP', name: 'COP', flag: '🇨🇴');

  static const usa = CountryOption(code: 'USA', name: 'USA', flag: '🇺🇸');

  static const mexico = CountryOption(code: 'MEX', name: 'MEX', flag: '🇲🇽');

  // List of available countries
  static const List<CountryOption> all = [colombia, usa, mexico];

  static const List<CountryOption> onlyColombia = [colombia];
}
