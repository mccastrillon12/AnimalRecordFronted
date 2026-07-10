import 'package:animal_record/core/network/api_client.dart';
import '../models/species_model.dart';
import '../models/breed_model.dart';
import '../models/catalog_item_model.dart';

abstract class CatalogsRemoteDataSource {
  Future<List<SpeciesModel>> getSpecies();
  Future<List<BreedModel>> getBreedsBySpecies(String speciesId, {String? purposeId});
  Future<List<CatalogItemModel>> getHousingTypes({String? speciesId});
  Future<List<CatalogItemModel>> getAnimalPurposes({String? speciesId});
  Future<List<CatalogItemModel>> getTemperaments({String? speciesId});
  Future<List<CatalogItemModel>> getAdoptionSources();
  Future<List<CatalogItemModel>> getIdentificationTypes({String? speciesId});
  Future<List<CatalogItemModel>> getRegistrationAssociations({String? speciesId});
}

class CatalogsRemoteDataSourceImpl implements CatalogsRemoteDataSource {
  final ApiClient apiClient;

  CatalogsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<SpeciesModel>> getSpecies() async {
    final response = await apiClient.get('/catalogs/species');
    final List<dynamic> data = response.data;
    return data.map((json) => SpeciesModel.fromJson(json)).toList();
  }

  @override
  Future<List<BreedModel>> getBreedsBySpecies(String speciesId, {String? purposeId}) async {
    final queryParams = <String, dynamic>{};
    if (purposeId != null) queryParams['purposeId'] = purposeId;

    final response = await apiClient.get(
      '/catalogs/species/$speciesId/breeds',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => BreedModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getHousingTypes({String? speciesId}) async {
    final queryParams = <String, dynamic>{};
    if (speciesId != null) queryParams['speciesId'] = speciesId;

    final response = await apiClient.get(
      '/catalogs/housing-types',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getAnimalPurposes({String? speciesId}) async {
    final queryParams = <String, dynamic>{};
    if (speciesId != null) queryParams['speciesId'] = speciesId;

    final response = await apiClient.get(
      '/catalogs/animal-purposes',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getTemperaments({String? speciesId}) async {
    final queryParams = <String, dynamic>{};
    if (speciesId != null) queryParams['speciesId'] = speciesId;

    final response = await apiClient.get(
      '/catalogs/temperaments',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getAdoptionSources() async {
    final response = await apiClient.get('/catalogs/adoption-sources');
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getIdentificationTypes({String? speciesId}) async {
    final queryParams = <String, dynamic>{};
    if (speciesId != null) queryParams['speciesId'] = speciesId;

    final response = await apiClient.get(
      '/catalogs/identification-types',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }

  @override
  Future<List<CatalogItemModel>> getRegistrationAssociations({String? speciesId}) async {
    final queryParams = <String, dynamic>{};
    if (speciesId != null) queryParams['speciesId'] = speciesId;

    final response = await apiClient.get(
      '/catalogs/registration-associations',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CatalogItemModel.fromJson(json)).toList();
  }
}
