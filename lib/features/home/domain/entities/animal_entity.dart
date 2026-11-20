import 'animal_ownership.dart';
import 'owner_history_period.dart';
import 'package:equatable/equatable.dart';

class NameHistoryItem extends Equatable {
  final String id;
  final String name;
  final String date;

  const NameHistoryItem({
    required this.id,
    required this.name,
    required this.date,
  });

  @override
  List<Object?> get props => [id, name, date];
}

/// Entity representing an animal returned from the API.
class AnimalEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String species;
  final String breed;
  final String sex;
  final String reproductiveStatus;
  final String? birthdate;
  final bool hasChip;
  final bool isAssociationMember;
  final List<String> temperament;
  final List<String> diagnosis;
  final String ownerId;
  final String? profilePictureUrl;
  final double? weight;
  final String? colorAndMarkings;
  final String? allergies;
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
  final bool isActive;
  final String? deactivationReason;
  final String? createdAt;
  final String? updatedAt;
  final String? ownerName;
  final List<NameHistoryItem> nameHistory;
  final List<OwnerHistoryPeriod> ownerHistory;
  final String? transferStatus;
  final bool readOnly;
  final AnimalOwnershipHistory? ownershipHistory;
  bool get isHistorical => historicalAnimal(transferStatus, readOnly);
  bool get canWrite => writableAnimal(transferStatus, readOnly);
  bool get canTransfer => isActive && canWrite && transferStatus == null;
  String get cardKey => isHistorical
      ? '$id/history/${ownershipHistory?.periodId ?? 'unknown'}'
      : '$id/current';

  const AnimalEntity({
    required this.id,
    required this.name,
    this.code,
    required this.species,
    required this.breed,
    required this.sex,
    required this.reproductiveStatus,
    this.birthdate,
    required this.hasChip,
    required this.isAssociationMember,
    required this.temperament,
    required this.diagnosis,
    required this.ownerId,
    this.profilePictureUrl,
    this.weight,
    this.colorAndMarkings,
    this.allergies,
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
    this.isActive = true,
    this.deactivationReason,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.nameHistory = const [],
    this.ownerHistory = const [],
    this.transferStatus,
    this.readOnly = false,
    this.ownershipHistory,
  });

  /// Keeps access from the own-animal list when a detail omits transfer flags.
  AnimalEntity withOwnershipAccessFrom(AnimalEntity current) {
    if (id != current.id) throw ArgumentError('El animal no coincide.');
    // An explicit restriction in the detail must never be relaxed by a stale list.
    if (!canWrite || current.canWrite) return this;
    return AnimalEntity(
      id: id,
      name: name,
      code: code,
      species: species,
      breed: breed,
      sex: sex,
      reproductiveStatus: reproductiveStatus,
      birthdate: birthdate,
      hasChip: hasChip,
      isAssociationMember: isAssociationMember,
      temperament: temperament,
      diagnosis: diagnosis,
      ownerId: ownerId,
      profilePictureUrl: profilePictureUrl,
      weight: weight,
      colorAndMarkings: colorAndMarkings,
      allergies: allergies,
      housingType: housingType,
      purpose: purpose,
      feedingType: feedingType,
      birthType: birthType,
      birthCondition: birthCondition,
      identificationType: identificationType,
      identificationNumber: identificationNumber,
      registrationAssociations: registrationAssociations,
      isAdopted: isAdopted,
      adoptionSource: adoptionSource,
      adoptionPlaceName: adoptionPlaceName,
      otherDiagnosisDetail: otherDiagnosisDetail,
      unknownBirthDate: unknownBirthDate,
      approximateAgeMinMonths: approximateAgeMinMonths,
      approximateAgeMaxMonths: approximateAgeMaxMonths,
      isActive: isActive,
      deactivationReason: deactivationReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerName: ownerName,
      nameHistory: nameHistory,
      ownerHistory: ownerHistory,
      transferStatus: current.transferStatus,
      readOnly: current.readOnly,
      ownershipHistory: ownershipHistory,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    species,
    breed,
    sex,
    reproductiveStatus,
    birthdate,
    hasChip,
    isAssociationMember,
    temperament,
    diagnosis,
    ownerId,
    profilePictureUrl,
    weight,
    colorAndMarkings,
    allergies,
    housingType,
    purpose,
    feedingType,
    birthType,
    birthCondition,
    identificationType,
    identificationNumber,
    registrationAssociations,
    isAdopted,
    adoptionSource,
    adoptionPlaceName,
    otherDiagnosisDetail,
    unknownBirthDate,
    approximateAgeMinMonths,
    approximateAgeMaxMonths,
    isActive,
    deactivationReason,
    createdAt,
    updatedAt,
    ownerName,
    nameHistory,
    ownerHistory,
    transferStatus,
    readOnly,
    ownershipHistory,
  ];
}

List<AnimalEntity> uniqueAnimalCards(Iterable<AnimalEntity> animals) {
  final currentIds = animals
      .where((animal) => !animal.isHistorical)
      .map((animal) => animal.id)
      .toSet();
  return {
    for (final animal in animals)
      if (!animal.isHistorical || !currentIds.contains(animal.id))
        animal.cardKey: animal,
  }.values.toList();
}
