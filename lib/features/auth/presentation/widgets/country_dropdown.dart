import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';

class CountryDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<CountryEntity> countries;
  final double? width;
  final bool enabled;

  const CountryDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.countries,
    this.width,
    this.enabled = true,
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
          width: width ?? 116,
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
            child: IgnorePointer(
              ignoring: !enabled,
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.greyMedio,
                ),
                items: countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country.id,
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/icons/${country.isoCode}.png',
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
                        Expanded(
                          child: Text(
                            country.name,
                            style: AppTypography.body4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
