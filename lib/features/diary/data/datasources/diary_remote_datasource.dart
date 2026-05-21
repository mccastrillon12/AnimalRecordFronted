import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/diary/data/models/diary_entry_model.dart';

abstract class DiaryRemoteDataSource {
  Future<List<DiaryEntryModel>> getDiaryEntries(String animalId);
  Future<DiaryEntryModel> createDiaryEntry(
    String animalId,
    Map<String, dynamic> data,
  );
  Future<DiaryEntryModel> updateDiaryEntry(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  );
  Future<void> deleteDiaryEntry(String animalId, String entryId);
  Future<Map<String, dynamic>> getAttachmentUploadUrl(
    String animalId,
    String entryId,
    String mimeType,
    int fileSize,
  );
  Future<DiaryEntryModel> confirmAttachment(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAttachment(
    String animalId,
    String entryId,
    String attachmentId,
  );
}

class DiaryRemoteDataSourceImpl implements DiaryRemoteDataSource {
  final ApiClient apiClient;

  DiaryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<DiaryEntryModel>> getDiaryEntries(String animalId) async {
    final response = await apiClient.get('/animals/$animalId/diary');
    final List<dynamic> list = response.data is List ? response.data : [];
    return list
        .map((json) => DiaryEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DiaryEntryModel> createDiaryEntry(
    String animalId,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.post(
      '/animals/$animalId/diary',
      data: data,
    );
    return DiaryEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DiaryEntryModel> updateDiaryEntry(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.put(
      '/animals/$animalId/diary/$entryId',
      data: data,
    );
    return DiaryEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDiaryEntry(String animalId, String entryId) async {
    await apiClient.delete('/animals/$animalId/diary/$entryId');
  }

  @override
  Future<Map<String, dynamic>> getAttachmentUploadUrl(
    String animalId,
    String entryId,
    String mimeType,
    int fileSize,
  ) async {
    final response = await apiClient.get(
      '/animals/$animalId/diary/$entryId/attachments/upload-url',
      queryParameters: {
        'mimeType': mimeType,
        'fileSize': fileSize.toString(),
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<DiaryEntryModel> confirmAttachment(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.post(
      '/animals/$animalId/diary/$entryId/attachments',
      data: data,
    );
    return DiaryEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAttachment(
    String animalId,
    String entryId,
    String attachmentId,
  ) async {
    await apiClient.delete(
      '/animals/$animalId/diary/$entryId/attachments/$attachmentId',
    );
  }
}
