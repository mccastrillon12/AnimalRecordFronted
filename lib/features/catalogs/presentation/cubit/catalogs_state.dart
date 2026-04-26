import 'package:equatable/equatable.dart';
import 'package:animal_record/features/catalogs/domain/entities/species_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/breed_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/catalog_item_entity.dart';

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

/// Emitted when all animal-specific catalogs finish loading
class AnimalCatalogsLoaded extends CatalogsState {
  final List<CatalogItemEntity> housingTypes;
  final List<CatalogItemEntity> animalPurposes;
  final List<CatalogItemEntity> temperaments;
  final List<CatalogItemEntity> identificationTypes;
  final List<CatalogItemEntity> registrationAssociations;
  final List<CatalogItemEntity> adoptionSources;

  const AnimalCatalogsLoaded({
    required this.housingTypes,
    required this.animalPurposes,
    required this.temperaments,
    required this.identificationTypes,
    required this.registrationAssociations,
    required this.adoptionSources,
  });

  @override
  List<Object?> get props => [
        housingTypes,
        animalPurposes,
        temperaments,
        identificationTypes,
        registrationAssociations,
        adoptionSources,
      ];
}

class CatalogsError extends CatalogsState {
  final String message;

  const CatalogsError(this.message);

  @override
  List<Object?> get props => [message];
}
