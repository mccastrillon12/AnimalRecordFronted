import 'dart:convert';
import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';

abstract class AnimalRemoteDataSource {
  Future<AnimalDataModel> createAnimal(Map<String, dynamic> data);
  Future<AnimalDataModel> updateAnimal(String id, Map<String, dynamic> data);
  Future<List<AnimalDataModel>> getAnimalsByOwner(String ownerId);
  Future<Map<String, dynamic>> getProfilePictureUploadUrl(
    String animalId,
    String mimeType,
    int fileSize,
  );
  Future<void> confirmProfilePicture(String animalId, String finalUrl);
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
  Future<AnimalDataModel> updateAnimal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.put('/animals/$id', data: data);
    
    dynamic responseData = response.data;
    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (_) {}
    }

    if (responseData is Map<String, dynamic>) {
      return AnimalDataModel.fromJson(responseData);
    }
    
    // Fallback in case backend returns a simple success string instead of the object
    // We try to construct a partial model using the sent data.
    final patchedData = Map<String, dynamic>.from(data);
    patchedData['id'] = id;
    return AnimalDataModel.fromJson(patchedData);
  }

  @override
  Future<List<AnimalDataModel>> getAnimalsByOwner(String ownerId) async {
    final response = await apiClient.get('/animals/owner/$ownerId');
    final List<dynamic> list = response.data is List ? response.data : [];
    return list
        .map((json) => AnimalDataModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getProfilePictureUploadUrl(
    String animalId,
    String mimeType,
    int fileSize,
  ) async {
    final response = await apiClient.get(
      '/animals/$animalId/profile-picture/upload-url',
      queryParameters: {'mimeType': mimeType, 'fileSize': fileSize.toString()},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> confirmProfilePicture(
    String animalId,
    String finalUrl,
  ) async {
    await apiClient.patch(
      '/animals/$animalId/profile-picture',
      data: {'finalUrl': finalUrl},
    );
  }
}
