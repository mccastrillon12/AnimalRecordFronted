import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String? password;

  const UserModel({
    required super.id,
    required super.name,
    required super.identificationType,
    required super.identificationNumber,
    required super.country,
    required super.countryId,
    required super.city,
    required super.email,
    required super.cellPhone,
    super.professionalCard,
    required super.animalTypes,
    required super.services,
    required super.isHomeDelivery,
    required super.roles,
    required super.authMethod,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      identificationType: json['identificationType'] ?? '',
      identificationNumber: json['identificationNumber'] ?? '',
      country: json['country'] ?? '',
      countryId: json['countryId'] ?? '',
      city: json['city'] ?? '',
      email: json['email'] ?? '',
      cellPhone: json['cellPhone'] ?? '',
      professionalCard: json['professionalCard'],
      animalTypes: List<String>.from(json['animalTypes'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      isHomeDelivery: json['isHomeDelivery'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
      authMethod: json['authMethod'] ?? 'EMAIL',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'identificationType': identificationType,
      'identificationNumber': identificationNumber,
      'countryId': countryId,
      'roles': roles,
      'authMethod': authMethod,
      'animalTypes': animalTypes,
      'services': services,
      'isHomeDelivery': isHomeDelivery,
    };

    // Only include email if not empty
    if (email.isNotEmpty) {
      json['email'] = email;
    }

    // Only include cellPhone if not empty
    if (cellPhone.isNotEmpty) {
      json['cellPhone'] = cellPhone;
    }

    // Only include optional fields if they are not empty
    if (city.isNotEmpty) {
      json['city'] = city;
    }

    if (professionalCard != null && professionalCard!.isNotEmpty) {
      json['professionalCard'] = professionalCard;
    }

    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }

    return json;
  }
}
