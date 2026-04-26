import '../../domain/entities/catalog_item_entity.dart';

class CatalogItemModel extends CatalogItemEntity {
  const CatalogItemModel({
    required super.id,
    required super.name,
    super.speciesId,
  });

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      speciesId: json['speciesId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (speciesId != null) 'speciesId': speciesId,
    };
  }
}
