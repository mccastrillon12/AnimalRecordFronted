import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';

abstract class AnimalRemoteDataSource {
  Future<AnimalDataModel> createAnimal(Map<String, dynamic> data);
  Future<List<AnimalDataModel>> getAnimalsByOwner(String ownerId);
}

class AnimalRemoteDataSourceImpl implements AnimalRemoteDataSource {
  final ApiClient apiClient;

  AnimalRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AnimalDataModel> createAnimal(Map<String, dynamic> data) async {
    final response = await apiClient.post('/animals', data: data);
    return AnimalDataModel.fromJson(response.data);
  }

  @override
  Future<List<AnimalDataModel>> getAnimalsByOwner(String ownerId) async {
    final response = await apiClient.get('/animals/owner/$ownerId');
    final List<dynamic> list = response.data is List ? response.data : [];
    return list
        .map((json) => AnimalDataModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
