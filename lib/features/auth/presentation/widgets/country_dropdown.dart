import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class CountryDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?>? onChanged;
  final List<CountryOption> countries;
  final double? width; // Optional width parameter

  const CountryDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.countries,
    this.width, // Default to 116 if not provided
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        SizedBox(
          height: 18,

          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: AppTypography.body6),
          ),
        ),

        const SizedBox(height: AppSpacing.inputTopPadding),

        // Dropdown container
        Container(
          height: AppSpacing.inputHeight,
          width: width ?? 116, // Use provided width or default to 116
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
            right: 12,
            left: 12,
          ),
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
                      ClipOval(
                        child: Image.asset(
                          country.imagePath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.greyMedio,
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ),
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
  final String imagePath;

  const CountryOption({
    required this.code,
    required this.name,
    required this.imagePath,
  });

  // Predefined countries
  static const colombia = CountryOption(
    code: 'COP',
    name: 'COP',
    imagePath: 'assets/icons/Colombia.png',
  );

  static const usa = CountryOption(
    code: 'USA',
    name: 'USA',
    imagePath: 'assets/icons/Colombia.png',
  );

  static const mexico = CountryOption(
    code: 'MEX',
    name: 'MEX',
    imagePath: 'assets/icons/Colombia.png',
  );

  // List of available countries
  static const List<CountryOption> all = [colombia, usa, mexico];

  static const List<CountryOption> onlyColombia = [colombia];
}
