import 'package:animal_record/features/home/domain/entities/animal_entity.dart';

/// Represents an animal registered in the system.
class AnimalModel {
  final String id;
  final String name;
  final String code;
  final String family;
  final String? breed;
  final String? sex;
  final String ageDisplay;
  final String? imageUrl;

  const AnimalModel({
    required this.id,
    required this.name,
    required this.code,
    required this.family,
    this.breed,
    this.sex,
    this.ageDisplay = '',
    this.imageUrl,
  });

  /// Maps an [AnimalEntity] (from the API) to the UI model.
  factory AnimalModel.fromEntity(AnimalEntity entity) {
    // Species → family label
    String familyLabel;
    switch (entity.species.toUpperCase()) {
      case 'CAT':
      case 'FELINE':
        familyLabel = 'Felino';
        break;
      case 'DOG':
      case 'CANINE':
        familyLabel = 'Canino';
        break;
      case 'COW':
      case 'BOVINE':
        familyLabel = 'Bovino';
        break;
      case 'HORSE':
      case 'EQUINE':
        familyLabel = 'Equino';
        break;
      default:
        if (entity.species.isNotEmpty) {
          familyLabel = entity.species[0].toUpperCase() + entity.species.substring(1).toLowerCase();
        } else {
          familyLabel = entity.species;
        }
    }

    String formattedName = entity.name.trim();
    if (formattedName.isNotEmpty) {
      formattedName = formattedName[0].toUpperCase() + formattedName.substring(1).toLowerCase();
    }

    // Calculate age from birthdate
    String calculatedAgeDisplay = '';
    if (entity.birthdate != null && entity.birthdate!.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(entity.birthdate!);
        final now = DateTime.now();
        final days = now.difference(birthDate).inDays;
        
        if (days < 30) {
          calculatedAgeDisplay = '$days día${days == 1 ? '' : 's'}';
        } else if (days < 365) {
          int months = (days / 30.4167).floor();
          if (months == 0) months = 1;
          calculatedAgeDisplay = '$months mes${months == 1 ? '' : 'es'}';
        } else {
          int years = now.year - birthDate.year;
          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
            years--;
          }
          calculatedAgeDisplay = '$years año${years == 1 ? '' : 's'}';
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
      name: formattedName,
      code: entity.code ?? 'AR-${entity.id.substring(0, 4).toUpperCase()}',
      family: familyLabel,
      breed: entity.breed,
      sex: sexDisplay,
      ageDisplay: calculatedAgeDisplay,
      imageUrl: null,
    );
  }



  String get sexDisplay {
    if (sex == null) return '';
    return sex == 'macho' ? 'Macho' : 'Hembra';
  }
}
