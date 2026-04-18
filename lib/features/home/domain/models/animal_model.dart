import 'package:animal_record/features/home/domain/entities/animal_entity.dart';

/// Represents an animal registered in the system.
class AnimalModel {
  final String id;
  final String name;
  final String code;
  final String family;
  final String? breed;
  final String? sex;
  final int? ageYears;
  final String? imageUrl;

  const AnimalModel({
    required this.id,
    required this.name,
    required this.code,
    required this.family,
    this.breed,
    this.sex,
    this.ageYears,
    this.imageUrl,
  });

  /// Maps an [AnimalEntity] (from the API) to the UI model.
  factory AnimalModel.fromEntity(AnimalEntity entity) {
    // Species → family label
    String familyLabel;
    switch (entity.species.toUpperCase()) {
      case 'CAT':
        familyLabel = 'Felino';
        break;
      case 'DOG':
        familyLabel = 'Canino';
        break;
      case 'COW':
        familyLabel = 'Bovino';
        break;
      case 'HORSE':
        familyLabel = 'Equino';
        break;
      default:
        familyLabel = entity.species;
    }

    // Calculate age from birthdate
    int? ageYears;
    if (entity.birthdate != null && entity.birthdate!.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(entity.birthdate!);
        final now = DateTime.now();
        ageYears = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          ageYears--;
        }
      } catch (_) {}
    }

    // Sex display
    String? sexDisplay;
    switch (entity.sex.toUpperCase()) {
      case 'MALE':
        sexDisplay = 'macho';
        break;
      case 'FEMALE':
        sexDisplay = 'hembra';
        break;
      default:
        sexDisplay = entity.sex.toLowerCase();
    }

    return AnimalModel(
      id: entity.id,
      name: entity.name,
      code: 'AR-${entity.id.substring(0, 4).toUpperCase()}',
      family: familyLabel,
      breed: entity.breed,
      sex: sexDisplay,
      ageYears: ageYears,
      imageUrl: null,
    );
  }

  String get ageDisplay {
    if (ageYears == null) return '';
    return '$ageYears año${ageYears == 1 ? '' : 's'}';
  }

  String get sexDisplay {
    if (sex == null) return '';
    return sex == 'macho' ? 'Macho' : 'Hembra';
  }
}
