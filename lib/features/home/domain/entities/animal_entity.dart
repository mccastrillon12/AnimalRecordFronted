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
  final String? registrationAssociation;
  final String? createdAt;
  final String? updatedAt;
  final String? ownerName;
  final List<NameHistoryItem> nameHistory;

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
    this.registrationAssociation,
    this.createdAt,
    this.updatedAt,
    this.ownerName,
    this.nameHistory = const [],
  });

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
        registrationAssociation,
        createdAt,
        updatedAt,
        ownerName,
        nameHistory,
      ];
}
