import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String? password;

  const UserModel({
    required super.id,
    required super.name,
    required super.identificationType,
    required super.identificationNumber,
    required super.country,
    required super.city,
    required super.email,
    required super.cellPhone,
    super.professionalCard,
    required super.animalTypes,
    required super.services,
    required super.isHomeDelivery,
    required super.roles,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      identificationType: json['identificationType'] ?? '',
      identificationNumber: json['identificationNumber'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      email: json['email'] ?? '',
      cellPhone: json['cellPhone'] ?? '',
      professionalCard: json['professionalCard'],
      animalTypes: List<String>.from(json['animalTypes'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      isHomeDelivery: json['isHomeDelivery'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'identificationType': identificationType,
      'identificationNumber': identificationNumber,
      'country': country,
      'city': city,
      'email': email,
      'cellPhone': cellPhone,
      'professionalCard': professionalCard,
      'animalTypes': animalTypes,
      'services': services,
      'isHomeDelivery': isHomeDelivery,
      'roles': roles,
      if (password != null) 'password': password,
    };
  }
}
