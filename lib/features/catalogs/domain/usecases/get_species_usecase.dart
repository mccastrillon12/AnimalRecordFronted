import '../repositories/catalogs_repository.dart';
import '../entities/species_entity.dart';

class GetSpeciesUseCase {
  final CatalogsRepository repository;

  GetSpeciesUseCase({required this.repository});

  Future<List<SpeciesEntity>> call() async {
    return await repository.getSpecies();
  }
}
