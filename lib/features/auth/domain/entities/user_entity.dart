import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String identificationType;
  final String identificationNumber;
  final String country;
  final String countryId;
  final String departmentId;
  final String city;
  final String cityId;
  final String address;
  final String email;
  final String cellPhone;
  final String? professionalCard;
  final List<String> animalTypes;
  final List<String> services;
  final bool isHomeDelivery;
  final List<String> roles;
  final String authMethod;

  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.name,
    required this.identificationType,
    required this.identificationNumber,
    required this.country,
    required this.countryId,
    required this.departmentId,
    required this.city,
    required this.cityId,
    this.address = '',
    required this.email,
    required this.cellPhone,
    this.professionalCard,
    required this.animalTypes,
    required this.services,
    required this.isHomeDelivery,
    required this.roles,
    required this.authMethod,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    identificationNumber,
    name,
    identificationType,
    country,
    countryId,
    departmentId,
    city,
    cityId,
    address,
    cellPhone,
    professionalCard,
    animalTypes,
    services,
    isHomeDelivery,
    roles,
    authMethod,
    isVerified,
  ];
}
