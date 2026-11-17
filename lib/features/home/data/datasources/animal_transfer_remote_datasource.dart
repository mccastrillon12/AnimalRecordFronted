import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/home/domain/services/animal_transfer_availability.dart';
import 'package:dio/dio.dart';

class AnimalTransferRemoteDataSource {
  final ApiClient apiClient;

  const AnimalTransferRemoteDataSource(this.apiClient);

  Future<List<dynamic>> getActiveAnimals() async {
    final response = await apiClient.get<dynamic>(
      '/animals/search',
      queryParameters: {'isActive': true},
      options: Options(extra: {'redactTransferPayload': true}),
    );
    final data = response.data;
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'animals']) {
        if (data[key] is List<dynamic>) return data[key] as List<dynamic>;
      }
    }
    throw const FormatException('Respuesta inválida de animales activos');
  }

  Future<Map<String, dynamic>> searchRecipients(
    String name, {
    String? cursor,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-transfers/recipients',
      queryParameters: {
        'searchBy': 'NAME',
        'q': name,
        'limit': 20,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response.data!;
  }

  Future<List<dynamic>> getReasons() async {
    final response = await apiClient.get<List<dynamic>>(
      '/catalogs/animal-transfer-reasons',
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> startChallenge() async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers/otp-challenges',
      data: <String, dynamic>{},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> resendChallenge(String id) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers/otp-challenges/${Uri.encodeComponent(id)}/resend',
      data: <String, dynamic>{},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> verifyChallenge(String id, String code) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers/otp-challenges/${Uri.encodeComponent(id)}/verify',
      data: {'code': code},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> createTransfer(
    String idempotencyKey,
    Map<String, Object> body,
  ) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers',
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw const FormatException('Respuesta de solicitud inválida');
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> listRequests({
    required String direction,
    String? status,
    String? cursor,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-transfers',
      queryParameters: {
        'direction': direction,
        'limit': 20,
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getDetail(String id, {String? cursor}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-transfers/${Uri.encodeComponent(id)}',
      queryParameters: {'limit': 20, if (cursor != null) 'cursor': cursor},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> decide({
    required String id,
    required int expectedVersion,
    required List<String> acceptedAnimalIds,
    required String idempotencyKey,
  }) async {
    if (acceptedAnimalIds.isNotEmpty &&
        !AnimalTransferAvailability.acceptance) {
      throw StateError('La aceptación está desactivada en este entorno.');
    }
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers/${Uri.encodeComponent(id)}/decisions',
      data: {
        'expectedVersion': expectedVersion,
        'acceptedAnimalIds': acceptedAnimalIds,
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> listHistory({String? cursor}) async {
    _requireHistory();
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-ownership-history',
      queryParameters: {'limit': 20, if (cursor != null) 'cursor': cursor},
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> getHistory(
    String periodId,
    String publicationHash, {
    String? cursor,
  }) async {
    _requireHistory();
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-ownership-history/${Uri.encodeComponent(periodId)}',
      queryParameters: {
        'limit': 20,
        'publicationHash': publicationHash,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response.data!;
  }

  Future<List<int>> downloadHistoricalFile({
    required String periodId,
    required String publicationHash,
    required String entryId,
    required String fileId,
  }) async {
    _requireHistory();
    final response = await apiClient.get<List<int>>(
      '/animal-ownership-history/${Uri.encodeComponent(periodId)}'
      '/entries/${Uri.encodeComponent(entryId)}/files/${Uri.encodeComponent(fileId)}',
      queryParameters: {'publicationHash': publicationHash},
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data!;
    final declaredLength = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    if (declaredLength != null && bytes.length != declaredLength) {
      throw StateError('Descarga incompleta');
    }
    return bytes;
  }

  void _requireHistory() {
    if (!AnimalTransferAvailability.history) {
      throw StateError('El histórico está desactivado en este entorno.');
    }
  }

  Future<Map<String, dynamic>> listNotifications({String? cursor}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'limit': 20, if (cursor != null) 'cursor': cursor},
    );
    return response.data!;
  }

  Future<int> unreadNotificationCount() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );
    return response.data!['count'] as int;
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await apiClient.patch<Map<String, dynamic>>(
      '/notifications/${Uri.encodeComponent(id)}/read',
      data: <String, dynamic>{},
    );
    return response.data!;
  }
}
