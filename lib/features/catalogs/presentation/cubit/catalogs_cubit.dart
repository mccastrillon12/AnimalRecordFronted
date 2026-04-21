import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/catalogs/domain/entities/species_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/breed_entity.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_species_usecase.dart';
import 'package:animal_record/features/catalogs/domain/usecases/get_breeds_usecase.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_state.dart';

class CatalogsCubit extends Cubit<CatalogsState> {
  final GetSpeciesUseCase getSpeciesUseCase;
  final GetBreedsBySpeciesUseCase getBreedsBySpeciesUseCase;

  CatalogsCubit({
    required this.getSpeciesUseCase,
    required this.getBreedsBySpeciesUseCase,
  }) : super(CatalogsInitial());

  List<SpeciesEntity> _species = [];
  List<BreedEntity> _breeds = [];
  final Map<String, List<BreedEntity>> _breedsCache = {};

  List<SpeciesEntity> get species => _species;
  List<BreedEntity> get breeds => _breeds;

  Future<void> loadSpecies() async {
    if (_species.isNotEmpty) {
      emit(SpeciesLoaded(_species));
      return;
    }

    emit(CatalogsLoading());
    try {
      _species = await getSpeciesUseCase();
      emit(SpeciesLoaded(_species));
    } catch (e) {
      emit(CatalogsError(e.toString()));
    }
  }

  Future<void> loadBreeds(String speciesId) async {
    if (_breedsCache.containsKey(speciesId)) {
      _breeds = _breedsCache[speciesId]!;
      emit(BreedsLoaded(species: _species, breeds: _breeds));
      return;
    }

    emit(BreedsLoading(_species));
    try {
      _breeds = await getBreedsBySpeciesUseCase(speciesId);
      _breedsCache[speciesId] = _breeds;
      emit(BreedsLoaded(species: _species, breeds: _breeds));
    } catch (e) {
      emit(CatalogsError(e.toString()));
    }
  }

  void reset() {
    _species = [];
    _breeds = [];
    _breedsCache.clear();
    emit(CatalogsInitial());
  }
}
