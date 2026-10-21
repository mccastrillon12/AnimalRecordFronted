import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';

bool matchesAnimalFilters(
  AnimalModel animal, {
  required String sex,
  required List<String> families,
  required List<String> ages,
  DateTime? currentDate,
}) {
  if (sex != 'Ambos' && animal.sexDisplay != sex) return false;
  if (families.isNotEmpty &&
      !families.contains(animalFamilyLabel(animal.family))) {
    return false;
  }
  if (ages.isEmpty) return true;

  final ageMonths = _ageInMonths(animal, currentDate ?? DateTime.now());
  if (ageMonths == null) return false;

  return ages.any((label) {
    final range = _ageRange(label);
    return ageMonths >= range.min && ageMonths <= range.max;
  });
}

int? _ageInMonths(AnimalModel animal, DateTime currentDate) {
  if (animal.approximateAgeMinMonths != null &&
      animal.approximateAgeMaxMonths != null) {
    return ((animal.approximateAgeMinMonths! +
                animal.approximateAgeMaxMonths!) /
            2)
        .round();
  }
  final birthdate = DateTime.tryParse(animal.birthdate ?? '');
  if (birthdate == null) return null;

  var months =
      (currentDate.year - birthdate.year) * 12 +
      currentDate.month -
      birthdate.month;
  if (currentDate.day < birthdate.day) months--;
  return months;
}

({int min, int max}) _ageRange(String label) => switch (label) {
  '0-6 meses' => (min: 0, max: 6),
  '7-11 meses' => (min: 7, max: 11),
  '1-3 años' => (min: 12, max: 36),
  '4-6 años' => (min: 48, max: 72),
  '7-10 años' => (min: 84, max: 120),
  '11-15 años' => (min: 132, max: 180),
  '16-20 años' => (min: 192, max: 240),
  '21-25 años' => (min: 252, max: 300),
  '+25 años' => (min: 301, max: 1200),
  _ => (min: 0, max: 1200),
};
