import '../../domain/entities/species_entity.dart';

class SpeciesModel extends SpeciesEntity {
  const SpeciesModel({
    required super.id,
    required super.name,
  });

  factory SpeciesModel.fromJson(Map<String, dynamic> json) {
    return SpeciesModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
