import '../entities/species_entity.dart';
import '../entities/breed_entity.dart';

abstract class CatalogsRepository {
  Future<List<SpeciesEntity>> getSpecies();
  Future<List<BreedEntity>> getBreedsBySpecies(String speciesId);
}
