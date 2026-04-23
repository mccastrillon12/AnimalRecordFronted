import 'package:animal_record/features/home/domain/entities/animal_entity.dart';

/// Data model for Animal with JSON serialization.
class AnimalDataModel extends AnimalEntity {
  const AnimalDataModel({
    required super.id,
    required super.name,
    super.code,
    required super.species,
    required super.breed,
    required super.sex,
    required super.reproductiveStatus,
    super.birthdate,
    required super.hasChip,
    required super.isAssociationMember,
    required super.temperament,
    required super.diagnosis,
    required super.ownerId,
    super.weight,
    super.colorAndMarkings,
    super.allergies,
    super.housingType,
    super.purpose,
    super.feedingType,
    super.birthType,
    super.birthCondition,
  });

  factory AnimalDataModel.fromJson(Map<String, dynamic> json) {
    return AnimalDataModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      species: json['species'] as String,
      breed: json['breed'] as String? ?? '',
      sex: json['sex'] as String,
      reproductiveStatus: json['reproductiveStatus'] as String? ?? '',
      birthdate: (json['birthdate'] ?? json['birthDate']) as String?,
      hasChip: json['hasChip'] as bool? ?? false,
      isAssociationMember: json['isAssociationMember'] as bool? ?? false,
      temperament: (json['temperament'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      diagnosis: (json['diagnosis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ownerId: json['ownerId'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      colorAndMarkings: json['colorAndMarkings'] as String?,
      allergies: json['allergies'] as String?,
      housingType: json['housingType'] as String?,
      purpose: json['purpose'] as String?,
      feedingType: json['feedingType'] as String?,
      birthType: json['birthType'] as String?,
      birthCondition: json['birthCondition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      'species': species,
      'breed': breed,
      'sex': sex,
      'reproductiveStatus': reproductiveStatus,
      if (birthdate != null) 'birthdate': birthdate,
      'hasChip': hasChip,
      'isAssociationMember': isAssociationMember,
      'temperament': temperament,
      'diagnosis': diagnosis,
      'ownerId': ownerId,
      if (weight != null) 'weight': weight,
      if (colorAndMarkings != null) 'colorAndMarkings': colorAndMarkings,
      if (allergies != null) 'allergies': allergies,
      if (housingType != null) 'housingType': housingType,
      if (purpose != null) 'purpose': purpose,
      if (feedingType != null) 'feedingType': feedingType,
      if (birthType != null) 'birthType': birthType,
      if (birthCondition != null) 'birthCondition': birthCondition,
    };
  }
}
