import 'package:equatable/equatable.dart';

/// Entity representing an animal returned from the API.
class AnimalEntity extends Equatable {
  final String id;
  final String name;
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
  final double? weight;
  final String? colorAndMarkings;
  final String? allergies;

  const AnimalEntity({
    required this.id,
    required this.name,
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
    this.weight,
    this.colorAndMarkings,
    this.allergies,
  });

  @override
  List<Object?> get props => [
        id,
        name,
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
        weight,
        colorAndMarkings,
        allergies,
      ];
}
