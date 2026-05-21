import '../../domain/entities/species_entity.dart';
import '../../domain/entities/breed_entity.dart';
import '../../domain/entities/catalog_item_entity.dart';
import '../../domain/repositories/catalogs_repository.dart';
import '../datasources/catalogs_remote_datasource.dart';

class CatalogsRepositoryImpl implements CatalogsRepository {
  final CatalogsRemoteDataSource remoteDataSource;

  CatalogsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<SpeciesEntity>> getSpecies() async {
    return await remoteDataSource.getSpecies();
  }

  @override
  Future<List<BreedEntity>> getBreedsBySpecies(String speciesId, {String? purposeId}) async {
    return await remoteDataSource.getBreedsBySpecies(speciesId, purposeId: purposeId);
  }

  @override
  Future<List<CatalogItemEntity>> getHousingTypes({String? speciesId}) async {
    return await remoteDataSource.getHousingTypes(speciesId: speciesId);
  }

  @override
  Future<List<CatalogItemEntity>> getAnimalPurposes({String? speciesId}) async {
    return await remoteDataSource.getAnimalPurposes(speciesId: speciesId);
  }

  @override
  Future<List<CatalogItemEntity>> getTemperaments({String? speciesId}) async {
    return await remoteDataSource.getTemperaments(speciesId: speciesId);
  }

  @override
  Future<List<CatalogItemEntity>> getAdoptionSources() async {
    return await remoteDataSource.getAdoptionSources();
  }

  @override
  Future<List<CatalogItemEntity>> getIdentificationTypes({String? speciesId}) async {
    return await remoteDataSource.getIdentificationTypes(speciesId: speciesId);
  }

  @override
  Future<List<CatalogItemEntity>> getRegistrationAssociations({String? speciesId}) async {
    return await remoteDataSource.getRegistrationAssociations(speciesId: speciesId);
  }
}
