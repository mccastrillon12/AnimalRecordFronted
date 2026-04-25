import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/locations/domain/entities/city_entity.dart';
import 'package:flutter/material.dart';

/// Thin wrapper over [AppDropdown] for selecting a city.
///
/// Accepts [CityEntity] list and exposes the selected city's **id**
/// through [onChanged], matching the previous API.
class CityDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<CityEntity> cities;
  final double? width;
  final bool enabled;
  final TextStyle? labelStyle;
  final bool pushContent;

  const CityDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.cities,
    this.width,
    this.enabled = true,
    this.labelStyle,
    this.pushContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final validCities =
        cities.where((c) => c.name.trim().isNotEmpty).toList();

    // Resolve the selected entity from the id
    CityEntity? selectedCity;
    if (value != null) {
      try {
        selectedCity = validCities.firstWhere((c) => c.id == value);
      } catch (_) {}
    }

    return AppDropdown<CityEntity>(
      label: label,
      hint: 'Selecciona una ciudad',
      value: selectedCity,
      items: validCities,
      itemAsString: (c) => c.name,
      onChanged: (city) => onChanged?.call(city?.id),
      enabled: enabled,
      width: width,
      labelStyle: labelStyle,
      pushContent: pushContent,
    );
  }
}
