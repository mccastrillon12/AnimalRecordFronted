import 'package:equatable/equatable.dart';
import '../../domain/entities/country_entity.dart';

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

  const LocationsLoaded({required this.countries});

  @override
  List<Object?> get props => [countries];
}

class LocationsError extends LocationsState {
  final String message;

  const LocationsError({required this.message});

  @override
  List<Object?> get props => [message];
}
