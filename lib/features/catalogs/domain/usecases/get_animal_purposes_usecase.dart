import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetAnimalPurposesUseCase {
  final CatalogsRepository repository;

  GetAnimalPurposesUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call({String? speciesId}) async {
    return await repository.getAnimalPurposes(speciesId: speciesId);
  }
}
