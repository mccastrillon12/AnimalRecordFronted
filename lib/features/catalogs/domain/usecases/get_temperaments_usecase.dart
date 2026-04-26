import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetTemperamentsUseCase {
  final CatalogsRepository repository;

  GetTemperamentsUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call({String? speciesId}) async {
    return await repository.getTemperaments(speciesId: speciesId);
  }
}
