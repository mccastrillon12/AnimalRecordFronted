import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/catalogs/domain/entities/species_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/breed_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/catalog_item_entity.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_species_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_breeds_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_housing_types_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_animal_purposes_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_temperaments_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_adoption_sources_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_identification_types_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_registration_associations_usecase.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_state.dart';

class CatalogsCubit extends Cubit<CatalogsState> {
  final GetSpeciesUseCase getSpeciesUseCase;
  final GetBreedsBySpeciesUseCase getBreedsBySpeciesUseCase;
  final GetHousingTypesUseCase getHousingTypesUseCase;
  final GetAnimalPurposesUseCase getAnimalPurposesUseCase;
  final GetTemperamentsUseCase getTemperamentsUseCase;
  final GetAdoptionSourcesUseCase getAdoptionSourcesUseCase;
  final GetIdentificationTypesUseCase getIdentificationTypesUseCase;
  final GetRegistrationAssociationsUseCase getRegistrationAssociationsUseCase;

  CatalogsCubit({
    required this.getSpeciesUseCase,
    required this.getBreedsBySpeciesUseCase,
    required this.getHousingTypesUseCase,
    required this.getAnimalPurposesUseCase,
    required this.getTemperamentsUseCase,
    required this.getAdoptionSourcesUseCase,
    required this.getIdentificationTypesUseCase,
    required this.getRegistrationAssociationsUseCase,
  }) : super(CatalogsInitial());

  List<SpeciesEntity> _species = [];
  List<BreedEntity> _breeds = [];
  final Map<String, List<BreedEntity>> _breedsCache = {};

  // Cached catalog lists
  List<CatalogItemEntity> _housingTypes = [];
  List<CatalogItemEntity> _animalPurposes = [];
  List<CatalogItemEntity> _temperaments = [];
  List<CatalogItemEntity> _adoptionSources = [];
  List<CatalogItemEntity> _identificationTypes = [];
  List<CatalogItemEntity> _registrationAssociations = [];

  // Cache keys for species-filtered catalogs
  final Map<String, List<CatalogItemEntity>> _housingTypesCache = {};
  final Map<String, List<CatalogItemEntity>> _animalPurposesCache = {};
  final Map<String, List<CatalogItemEntity>> _temperamentsCache = {};
  final Map<String, List<CatalogItemEntity>> _identificationTypesCache = {};
  final Map<String, List<CatalogItemEntity>> _registrationAssociationsCache = {};

  List<SpeciesEntity> get species => _species;
  List<BreedEntity> get breeds => _breeds;
  List<CatalogItemEntity> get housingTypes => _housingTypes;
  List<CatalogItemEntity> get animalPurposes => _animalPurposes;
  List<CatalogItemEntity> get temperaments => _temperaments;
  List<CatalogItemEntity> get adoptionSources => _adoptionSources;
  List<CatalogItemEntity> get identificationTypes => _identificationTypes;
  List<CatalogItemEntity> get registrationAssociations => _registrationAssociations;

  Future<void> loadSpecies() async {
    if (_species.isNotEmpty) {
      emit(SpeciesLoaded(_species));
      return;
    }

    emit(CatalogsLoading());
    try {
      final fetchedSpecies = await getSpeciesUseCase();
      _species = List.from(fetchedSpecies)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(SpeciesLoaded(_species));
    } catch (e) {
      emit(CatalogsError(e.toString()));
    }
  }

  Future<void> loadBreeds(String speciesId, {String? purposeId}) async {
    final cacheKey = purposeId != null ? '${speciesId}_$purposeId' : speciesId;

    if (_breedsCache.containsKey(cacheKey)) {
      _breeds = _breedsCache[cacheKey]!;
      emit(BreedsLoaded(species: _species, breeds: _breeds));
      return;
    }

    emit(BreedsLoading(_species));
    try {
      final fetchedBreeds = await getBreedsBySpeciesUseCase(speciesId, purposeId: purposeId);
      _breeds = List.from(fetchedBreeds)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _breedsCache[cacheKey] = _breeds;
      emit(BreedsLoaded(species: _species, breeds: _breeds));
    } catch (e) {
      emit(CatalogsError(e.toString()));
    }
  }

  /// Load all animal-related catalogs for a specific species.
  /// This fetches housing types, purposes, temperaments, identification types,
  /// and registration associations filtered by species, plus global adoption sources.
  Future<void> loadAnimalCatalogs({String? speciesId}) async {
    final cacheKey = speciesId ?? '_all';

    // Check if all caches are populated for this species
    if (_housingTypesCache.containsKey(cacheKey) &&
        _animalPurposesCache.containsKey(cacheKey) &&
        _temperamentsCache.containsKey(cacheKey) &&
        _identificationTypesCache.containsKey(cacheKey) &&
        _registrationAssociationsCache.containsKey(cacheKey) &&
        _adoptionSources.isNotEmpty) {
      _housingTypes = _housingTypesCache[cacheKey]!;
      _animalPurposes = _animalPurposesCache[cacheKey]!;
      _temperaments = _temperamentsCache[cacheKey]!;
      _identificationTypes = _identificationTypesCache[cacheKey]!;
      _registrationAssociations = _registrationAssociationsCache[cacheKey]!;
      _emitAnimalCatalogsLoaded();
      return;
    }

    try {
      // Fetch all catalogs in parallel
      final results = await Future.wait([
        getHousingTypesUseCase(speciesId: speciesId),
        getAnimalPurposesUseCase(speciesId: speciesId),
        getTemperamentsUseCase(speciesId: speciesId),
        getIdentificationTypesUseCase(speciesId: speciesId),
        getRegistrationAssociationsUseCase(speciesId: speciesId),
        getAdoptionSourcesUseCase(),
      ]);

      _housingTypes = (results[0] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _animalPurposes = (results[1] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _temperaments = (results[2] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _identificationTypes = (results[3] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _registrationAssociations = (results[4] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _adoptionSources = (results[5] as List<CatalogItemEntity>).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Cache by species
      _housingTypesCache[cacheKey] = _housingTypes;
      _animalPurposesCache[cacheKey] = _animalPurposes;
      _temperamentsCache[cacheKey] = _temperaments;
      _identificationTypesCache[cacheKey] = _identificationTypes;
      _registrationAssociationsCache[cacheKey] = _registrationAssociations;

      _emitAnimalCatalogsLoaded();
    } catch (e) {
      emit(CatalogsError(e.toString()));
    }
  }

  void _emitAnimalCatalogsLoaded() {
    emit(AnimalCatalogsLoaded(
      housingTypes: _housingTypes,
      animalPurposes: _animalPurposes,
      temperaments: _temperaments,
      identificationTypes: _identificationTypes,
      registrationAssociations: _registrationAssociations,
      adoptionSources: _adoptionSources,
    ));
  }

  void reset() {
    _species = [];
    _breeds = [];
    _breedsCache.clear();
    _housingTypes = [];
    _animalPurposes = [];
    _temperaments = [];
    _adoptionSources = [];
    _identificationTypes = [];
    _registrationAssociations = [];
    _housingTypesCache.clear();
    _animalPurposesCache.clear();
    _temperamentsCache.clear();
    _identificationTypesCache.clear();
    _registrationAssociationsCache.clear();
    emit(CatalogsInitial());
  }
}
