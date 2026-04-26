import '../repositories/catalogs_repository.dart';
import '../entities/catalog_item_entity.dart';

class GetRegistrationAssociationsUseCase {
  final CatalogsRepository repository;

  GetRegistrationAssociationsUseCase({required this.repository});

  Future<List<CatalogItemEntity>> call({String? speciesId}) async {
    return await repository.getRegistrationAssociations(speciesId: speciesId);
  }
}
