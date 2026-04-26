import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetIdentificationTypesUseCase {
  final CatalogsRepository repository;

  GetIdentificationTypesUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call({String? speciesId}) async {
    return await repository.getIdentificationTypes(speciesId: speciesId);
  }
}
