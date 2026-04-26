import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetHousingTypesUseCase {
  final CatalogsRepository repository;

  GetHousingTypesUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call({String? speciesId}) async {
    return await repository.getHousingTypes(speciesId: speciesId);
  }
}
