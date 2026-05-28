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
  final List<String> temperament;
  final String? allergies;
  final List<String> diagnosis;

  // Fields needed for the info/edit screen
  final String species;
  final String reproductiveStatus;
  final String? birthdate;
  final double? weight;
  final String? colorAndMarkings;
  final bool hasChip;
  final bool isAssociationMember;
  final String ownerId;
  final String? housingType;
  final String? purpose;
  final String? feedingType;
  final String? birthType;
  final String? birthCondition;
  final String? identificationType;
  final String? identificationNumber;
  final List<String>? registrationAssociations;
  final bool? isAdopted;
  final String? adoptionSource;
  final String? adoptionPlaceName;
  final String? otherDiagnosisDetail;
  final bool unknownBirthDate;
  final int? approximateAgeMinMonths;
  final int? approximateAgeMaxMonths;
  final String? createdAt;
  final String? updatedAt;
  final String? ownerName;
  final List<NameHistoryItem> nameHistory;
  final bool isActive;
  final String? deactivationReason;

  const AnimalModel({
    required this.id,
    required this.name,
    required this.code,
    required this.family,
    this.breed,
    this.sex,
    this.ageDisplay = '',
    this.imageUrl,
    this.temperament = const [],
    this.allergies,
    this.diagnosis = const [],
    this.species = '',
    this.reproductiveStatus = '',
    this.birthdate,
    this.weight,
    this.colorAndMarkings,
    this.hasChip = false,
    this.isAssociationMember = false,
    this.ownerId = '',
    this.housingType,
    this.purpose,
    this.feedingType,
    this.birthType,
    this.birthCondition,
    this.identificationType,
    this.identificationNumber,
    this.registrationAssociations,
    this.isAdopted,
    this.adoptionSource,
    this.adoptionPlaceName,
    this.otherDiagnosisDetail,
    this.unknownBirthDate = false,
    this.approximateAgeMinMonths,
    this.approximateAgeMaxMonths,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.nameHistory = const [],
    this.isActive = true,
    this.deactivationReason,
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
          familyLabel =
              entity.species[0].toUpperCase() +
              entity.species.substring(1).toLowerCase();
        } else {
          familyLabel = entity.species;
        }
    }

    String formattedName = entity.name.trim();
    if (formattedName.isNotEmpty) {
      formattedName =
          formattedName[0].toUpperCase() +
          formattedName.substring(1).toLowerCase();
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
          if (now.month < birthDate.month ||
              (now.month == birthDate.month && now.day < birthDate.day)) {
            years--;
          }
          calculatedAgeDisplay = '$years año${years == 1 ? '' : 's'}';
        }
      } catch (_) {}
    }

    // If unknownBirthDate is true and we have approximate months, use that instead
    if (entity.unknownBirthDate &&
        entity.approximateAgeMinMonths != null &&
        entity.approximateAgeMaxMonths != null) {
      calculatedAgeDisplay = _approximateAgeLabel(
        entity.approximateAgeMinMonths!,
        entity.approximateAgeMaxMonths!,
      );
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
      imageUrl: entity.profilePictureUrl,
      temperament: entity.temperament,
      allergies: entity.allergies,
      diagnosis: entity.diagnosis,
      species: entity.species,
      reproductiveStatus: entity.reproductiveStatus,
      birthdate: entity.birthdate,
      weight: entity.weight,
      colorAndMarkings: entity.colorAndMarkings,
      hasChip: entity.hasChip,
      isAssociationMember: entity.isAssociationMember,
      ownerId: entity.ownerId,
      housingType: entity.housingType,
      purpose: entity.purpose,
      feedingType: entity.feedingType,
      birthType: entity.birthType,
      birthCondition: entity.birthCondition,
      identificationType: entity.identificationType,
      identificationNumber: entity.identificationNumber,
      registrationAssociations: entity.registrationAssociations,
      isAdopted: entity.isAdopted,
      adoptionSource: entity.adoptionSource,
      adoptionPlaceName: entity.adoptionPlaceName,
      otherDiagnosisDetail: entity.otherDiagnosisDetail,
      unknownBirthDate: entity.unknownBirthDate,
      approximateAgeMinMonths: entity.approximateAgeMinMonths,
      approximateAgeMaxMonths: entity.approximateAgeMaxMonths,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      ownerName: entity.ownerName,
      nameHistory: entity.nameHistory,
      isActive: entity.isActive,
      deactivationReason: entity.deactivationReason,
    );
  }

  String get sexDisplay {
    if (sex == null) return '';
    return sex == 'macho' ? 'Macho' : 'Hembra';
  }

  /// Reverse-maps (min, max) months to a human-readable approximate age label.
  static String _approximateAgeLabel(int min, int max) {
    const ranges = {
      '0-6 meses': (0, 6),
      '7-11 meses': (7, 11),
      '1-3 años': (12, 36),
      '4-6 años': (48, 72),
      '7-10 años': (84, 120),
      '11-15 años': (132, 180),
      '16-20 años': (192, 240),
      '21-25 años': (252, 300),
      '+25 años': (300, 1200),
    };
    for (final entry in ranges.entries) {
      if (entry.value.$1 == min && entry.value.$2 == max) {
        return entry.key;
      }
    }
    // Fallback: show month range
    return '$min-$max meses';
  }
}
