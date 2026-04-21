import '../../domain/entities/species_entity.dart';
import '../../domain/entities/breed_entity.dart';
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
  Future<List<BreedEntity>> getBreedsBySpecies(String speciesId) async {
    return await remoteDataSource.getBreedsBySpecies(speciesId);
  }
}
