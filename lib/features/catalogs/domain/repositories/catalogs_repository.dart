import '../entities/species_entity.dart';
import '../entities/breed_entity.dart';
import '../entities/catalog_item_entity.dart';

abstract class CatalogsRepository {
  Future<List<SpeciesEntity>> getSpecies();
  Future<List<BreedEntity>> getBreedsBySpecies(String speciesId, {String? purposeId});
  Future<List<CatalogItemEntity>> getHousingTypes({String? speciesId});
  Future<List<CatalogItemEntity>> getAnimalPurposes({String? speciesId});
  Future<List<CatalogItemEntity>> getTemperaments({String? speciesId});
  Future<List<CatalogItemEntity>> getAdoptionSources();
  Future<List<CatalogItemEntity>> getIdentificationTypes({String? speciesId});
  Future<List<CatalogItemEntity>> getRegistrationAssociations({String? speciesId});
}
