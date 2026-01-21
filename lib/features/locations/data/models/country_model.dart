import '../../domain/entities/country_entity.dart';

class CountryModel extends CountryEntity {
  const CountryModel({
    required super.id,
    required super.name,
    required super.isoCode,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isoCode: json['isoCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'isoCode': isoCode};
  }
}
