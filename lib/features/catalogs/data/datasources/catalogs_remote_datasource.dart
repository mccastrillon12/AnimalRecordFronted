import 'package:animal_record/core/network/api_client.dart';
import '../models/species_model.dart';
import '../models/breed_model.dart';

abstract class CatalogsRemoteDataSource {
  Future<List<SpeciesModel>> getSpecies();
  Future<List<BreedModel>> getBreedsBySpecies(String speciesId);
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
  Future<List<BreedModel>> getBreedsBySpecies(String speciesId) async {
    final response = await apiClient.get(
      '/catalogs/species/$speciesId/breeds',
    );
    final List<dynamic> data = response.data;
    return data.map((json) => BreedModel.fromJson(json)).toList();
  }
}
