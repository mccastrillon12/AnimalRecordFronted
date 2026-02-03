import 'package:equatable/equatable.dart';
import '../../domain/entities/country_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/city_entity.dart';

abstract class LocationsState extends Equatable {
  const LocationsState();

  @override
  List<Object?> get props => [];
}

class LocationsInitial extends LocationsState {
  const LocationsInitial();
}

class LocationsLoading extends LocationsState {
  const LocationsLoading();
}

class LocationsLoaded extends LocationsState {
  final List<CountryEntity> countries;
  final List<DepartmentEntity> departments;
  final List<CityEntity> cities;

  const LocationsLoaded({
    required this.countries,
    this.departments = const [],
    this.cities = const [],
  });

  @override
  List<Object?> get props => [countries, departments, cities];

  LocationsLoaded copyWith({
    List<CountryEntity>? countries,
    List<DepartmentEntity>? departments,
    List<CityEntity>? cities,
  }) {
    return LocationsLoaded(
      countries: countries ?? this.countries,
      departments: departments ?? this.departments,
      cities: cities ?? this.cities,
    );
  }
}

class LocationsError extends LocationsState {
  final String message;

  const LocationsError({required this.message});

  @override
  List<Object?> get props => [message];
}
