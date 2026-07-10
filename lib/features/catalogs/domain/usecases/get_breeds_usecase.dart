import '../repositories/catalogs_repository.dart';
import '../entities/breed_entity.dart';

class GetBreedsBySpeciesUseCase {
  final CatalogsRepository repository;

  GetBreedsBySpeciesUseCase({required this.repository});

  Future<List<BreedEntity>> call(String speciesId, {String? purposeId}) async {
    return await repository.getBreedsBySpecies(speciesId, purposeId: purposeId);
  }
}
