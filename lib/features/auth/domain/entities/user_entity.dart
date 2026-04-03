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
  final String? profilePicture;

  final bool isVerified;
  final DateTime? securityLastUpdated;

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
    this.profilePicture,
    this.securityLastUpdated,
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
    profilePicture,
    securityLastUpdated,
  ];

  UserEntity copyWith({
    String? id,
    String? name,
    String? identificationType,
    String? identificationNumber,
    String? country,
    String? countryId,
    String? departmentId,
    String? city,
    String? cityId,
    String? address,
    String? email,
    String? cellPhone,
    String? professionalCard,
    List<String>? animalTypes,
    List<String>? services,
    bool? isHomeDelivery,
    List<String>? roles,
    String? authMethod,
    bool? isVerified,
    String? profilePicture,
    DateTime? securityLastUpdated,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      identificationType: identificationType ?? this.identificationType,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      country: country ?? this.country,
      countryId: countryId ?? this.countryId,
      departmentId: departmentId ?? this.departmentId,
      city: city ?? this.city,
      cityId: cityId ?? this.cityId,
      address: address ?? this.address,
      email: email ?? this.email,
      cellPhone: cellPhone ?? this.cellPhone,
      professionalCard: professionalCard ?? this.professionalCard,
      animalTypes: animalTypes ?? this.animalTypes,
      services: services ?? this.services,
      isHomeDelivery: isHomeDelivery ?? this.isHomeDelivery,
      roles: roles ?? this.roles,
      authMethod: authMethod ?? this.authMethod,
      isVerified: isVerified ?? this.isVerified,
      profilePicture: profilePicture ?? this.profilePicture,
      securityLastUpdated: securityLastUpdated ?? this.securityLastUpdated,
    );
  }
}
