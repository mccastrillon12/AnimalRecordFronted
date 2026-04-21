import '../../domain/entities/breed_entity.dart';

class BreedModel extends BreedEntity {
  const BreedModel({
    required super.id,
    required super.name,
  });

  factory BreedModel.fromJson(Map<String, dynamic> json) {
    return BreedModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
