import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetAdoptionSourcesUseCase {
  final CatalogsRepository repository;

  GetAdoptionSourcesUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call() async {
    return await repository.getAdoptionSources();
  }
}
