import 'package:equatable/equatable.dart';

class RegisterParams extends Equatable {
  final String id;
  final String name;
  final String email;
  final String password;
  final String identificationType;
  final String identificationNumber;
  final String country;
  final String countryId;
  final String city;
  final String cellPhone;
  final String? professionalCard;
  final List<String> roles;
  final List<String> animalTypes;
  final List<String> services;
  final bool isHomeDelivery;
  final String authMethod;

  const RegisterParams({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.identificationType,
    required this.identificationNumber,
    required this.country,
    required this.countryId,
    required this.city,
    required this.cellPhone,
    this.professionalCard,
    required this.roles,
    required this.animalTypes,
    required this.services,
    required this.isHomeDelivery,
    required this.authMethod,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    password,
    identificationType,
    identificationNumber,
    country,
    countryId,
    city,
    cellPhone,
    professionalCard,
    roles,
    animalTypes,
    services,
    isHomeDelivery,
    authMethod,
  ];
}
