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
    required super.departmentId,
    required super.city,
    required super.cityId,
    super.address,
    required super.email,
    required super.cellPhone,
    super.professionalCard,
    required super.animalTypes,
    required super.services,
    required super.isHomeDelivery,
    required super.roles,
    required super.authMethod,
    required super.isVerified,
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
      departmentId: json['departmentId'] ?? '',
      city: json['city'] ?? '',
      cityId: json['cityId'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      cellPhone: json['cellPhone'] ?? '',
      professionalCard: json['professionalCard'],
      animalTypes: List<String>.from(json['animalTypes'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      isHomeDelivery: json['isHomeDelivery'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
      authMethod: json['authMethod'] ?? 'EMAIL',
      isVerified: json['isVerified'] ?? false,
    );
  }

  factory UserModel.empty() {
    return const UserModel(
      id: '',
      name: '',
      identificationType: '',
      identificationNumber: '',
      country: '',
      countryId: '',
      departmentId: '',
      city: '',
      cityId: '',
      email: '',
      cellPhone: '',
      animalTypes: [],
      services: [],
      isHomeDelivery: false,
      roles: [],
      authMethod: '',
      isVerified: false,
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

    if (email.isNotEmpty) {
      json['email'] = email;
    }

    if (cellPhone.isNotEmpty) {
      json['cellPhone'] = cellPhone;
    }

    if (city.isNotEmpty) {
      json['city'] = city;
    }

    if (address.isNotEmpty) {
      json['address'] = address;
    }

    if (country.isNotEmpty) {
      json['country'] = country;
    }

    if (departmentId.isNotEmpty) {
      json['departmentId'] = departmentId;
    }

    if (cityId.isNotEmpty) {
      json['cityId'] = cityId;
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
