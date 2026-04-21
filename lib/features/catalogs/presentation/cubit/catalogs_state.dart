import 'package:equatable/equatable.dart';
import 'package:animal_record/features/catalogs/domain/entities/species_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/breed_entity.dart';

abstract class CatalogsState extends Equatable {
  const CatalogsState();

  @override
  List<Object?> get props => [];
}

class CatalogsInitial extends CatalogsState {}

class CatalogsLoading extends CatalogsState {}

class SpeciesLoaded extends CatalogsState {
  final List<SpeciesEntity> species;

  const SpeciesLoaded(this.species);

  @override
  List<Object?> get props => [species];
}

class BreedsLoading extends CatalogsState {
  final List<SpeciesEntity> species;

  const BreedsLoading(this.species);

  @override
  List<Object?> get props => [species];
}

class BreedsLoaded extends CatalogsState {
  final List<SpeciesEntity> species;
  final List<BreedEntity> breeds;

  const BreedsLoaded({required this.species, required this.breeds});

  @override
  List<Object?> get props => [species, breeds];
}

class CatalogsError extends CatalogsState {
  final String message;

  const CatalogsError(this.message);

  @override
  List<Object?> get props => [message];
}
