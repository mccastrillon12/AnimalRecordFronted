import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import 'package:flutter/material.dart';

/// Thin wrapper over [AppDropdown] for selecting a country.
///
/// Uses a custom [itemBuilder] to display flag icons alongside country names,
/// and a custom [triggerBuilder] to show the selected flag in the trigger box.
class CountryDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<CountryEntity> countries;
  final double? width;
  final bool enabled;
  final bool showIsoCodeAsValue;
  final TextStyle? labelStyle;
  final bool pushContent;

  const CountryDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.countries,
    this.width,
    this.enabled = true,
    this.showIsoCodeAsValue = false,
    this.labelStyle,
    this.pushContent = true,
  });

  String _displayText(CountryEntity c) =>
      showIsoCodeAsValue ? c.isoCode : c.name;

  Widget _buildFlagRow(CountryEntity country) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/icons/${country.isoCode}.png',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.greyMedio,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            _displayText(country),
            style: AppTypography.body4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCountries =
        countries.where((c) => c.name.trim().isNotEmpty).toList();

    // Resolve the selected entity from the id
    CountryEntity? selectedCountry;
    if (value != null) {
      try {
        selectedCountry = validCountries.firstWhere((c) => c.id == value);
      } catch (_) {
        if (validCountries.isNotEmpty) {
          selectedCountry = validCountries.first;
        }
      }
    }

    return AppDropdown<CountryEntity>(
      label: label,
      hint: 'Selecciona un país',
      value: selectedCountry,
      items: validCountries,
      itemAsString: _displayText,
      onChanged: (country) => onChanged?.call(country?.id),
      enabled: enabled,
      width: width ?? 116,
      labelStyle: labelStyle,
      showClearOption: false,
      pushContent: pushContent,
      itemBuilder: (country, _) => _buildFlagRow(country),
      triggerBuilder: (selected) {
        if (selected == null) {
          return Text(
            'Selecciona un país',
            style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
            overflow: TextOverflow.ellipsis,
          );
        }
        return _buildFlagRow(selected);
      },
    );
  }
}
