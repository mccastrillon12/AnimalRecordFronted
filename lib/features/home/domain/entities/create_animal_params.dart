import 'package:equatable/equatable.dart';

/// Parameters for the POST /animals endpoint.
class CreateAnimalParams extends Equatable {
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
  final String? housingType;
  final String? purpose;
  final String? feedingType;
  final String? birthType;
  final String? birthCondition;
  final String? identificationType;
  final String? registrationAssociation;

  const CreateAnimalParams({
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
    this.housingType,
    this.purpose,
    this.feedingType,
    this.birthType,
    this.birthCondition,
    this.identificationType,
    this.registrationAssociation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'reproductiveStatus': reproductiveStatus,
      if (birthdate != null) 'birthDate': birthdate,
      'hasChip': hasChip,
      'isAssociationMember': isAssociationMember,
      'temperament': temperament,
      'diagnosis': diagnosis,
      'ownerId': ownerId,
      if (weight != null) 'weight': weight,
      if (colorAndMarkings != null && colorAndMarkings!.isNotEmpty)
        'colorAndMarkings': colorAndMarkings,
      if (allergies != null && allergies!.isNotEmpty) 'allergies': allergies,
      if (housingType != null && housingType!.isNotEmpty)
        'housingType': housingType,
      if (purpose != null && purpose!.isNotEmpty) 'purpose': purpose,
      if (feedingType != null && feedingType!.isNotEmpty)
        'feedingType': feedingType,
      if (birthType != null && birthType!.isNotEmpty) 'birthType': birthType,
      if (birthCondition != null && birthCondition!.isNotEmpty)
        'birthCondition': birthCondition,
      if (identificationType != null && identificationType!.isNotEmpty)
        'identificationType': identificationType,
      if (registrationAssociation != null && registrationAssociation!.isNotEmpty)
        'registrationAssociation': registrationAssociation,
    };
  }

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
        housingType,
        purpose,
        feedingType,
        birthType,
        birthCondition,
        identificationType,
        registrationAssociation,
      ];
}
