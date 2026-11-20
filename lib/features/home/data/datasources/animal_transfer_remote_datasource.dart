import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/home/domain/entities/historical_file_download.dart';
import 'package:animal_record/features/home/domain/services/animal_transfer_availability.dart';
import 'package:dio/dio.dart';

class AnimalTransferRemoteDataSource {
  static final _documentCharacters = RegExp(r'^[A-Za-z0-9]+$');
  static final _digit = RegExp(r'[0-9]');

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
    String query, {
    String? cursor,
  }) async {
    query = query.trim();
    if (query.length < 2 || query.length > 100) {
      throw const FormatException(
        'La búsqueda debe tener entre 2 y 100 caracteres.',
      );
    }
    final isDocument =
        _documentCharacters.hasMatch(query) && _digit.hasMatch(query);
    final response = await apiClient.get<Map<String, dynamic>>(
      '/animal-transfers/recipients',
      queryParameters: {
        'searchBy': isDocument ? 'IDENTIFICATION' : 'NAME',
        'q': query,
        'limit': 20,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response.data!;
  }

  Future<List<dynamic>> getReasons() async {
    final response = await apiClient.get<List<dynamic>>(
      '/catalogs/animal-transfer-reasons',
      options: Options(headers: {'Cache-Control': 'no-cache'}),
    );
    return response.data!;
  }

  Future<List<dynamic>> getRejectionReasons() async {
    final response = await apiClient.get<List<dynamic>>(
      '/catalogs/animal-transfer-rejection-reasons',
      options: Options(headers: {'Cache-Control': 'no-cache'}),
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
    if (direction != 'INCOMING' && direction != 'OUTGOING') {
      throw const FormatException('Dirección de transferencia inválida.');
    }
    if (status != null && status != 'PENDING' && status != 'REJECTED') {
      throw const FormatException('Filtro de transferencia inválido.');
    }
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
    String? rejectionReasonCode,
    String? rejectionComment,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/animal-transfers/${Uri.encodeComponent(id)}/decisions',
      data: {
        'expectedVersion': expectedVersion,
        'acceptedAnimalIds': acceptedAnimalIds,
        if (rejectionReasonCode != null)
          'rejectionReasonCode': rejectionReasonCode,
        if (rejectionComment != null) 'rejectionComment': rejectionComment,
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
    // A transferred card always needs its publication, in every environment.
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
  }) async => (await downloadHistoricalFileData(
    periodId: periodId,
    publicationHash: publicationHash,
    entryId: entryId,
    fileId: fileId,
  )).bytes;

  Future<HistoricalFileDownload> downloadHistoricalFileData({
    required String periodId,
    required String publicationHash,
    required String entryId,
    required String fileId,
  }) async {
    final response = await apiClient.get<List<int>>(
      '/animal-ownership-history/${Uri.encodeComponent(periodId)}'
      '/entries/${Uri.encodeComponent(entryId)}/files/${Uri.encodeComponent(fileId)}',
      queryParameters: {'publicationHash': publicationHash},
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept-Encoding': 'identity'},
      ),
    );
    final bytes = response.data!;
    if (response.statusCode != 200 ||
        response.headers.value('content-range') != null) {
      throw const FormatException('La descarga histórica está incompleta.');
    }
    final declaredLength = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    if (declaredLength != null && bytes.length != declaredLength) {
      throw StateError('Descarga incompleta');
    }
    return HistoricalFileDownload(
      bytes: bytes,
      mimeType: response.headers
          .value('content-type')
          ?.split(';')
          .first
          .trim()
          .toLowerCase(),
      fileName: _downloadName(response.headers.value('content-disposition')),
    );
  }

  String? _downloadName(String? disposition) {
    if (disposition == null) return null;
    String? name;
    final encoded = RegExp(
      r"filename\*\s*=\s*UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    if (encoded != null) {
      try {
        name = Uri.decodeComponent(encoded.trim());
      } on FormatException {
        // Fall back to the plain filename, if present.
      }
    }
    name ??=
        RegExp(
          r'filename\s*=\s*"([^"]+)"',
          caseSensitive: false,
        ).firstMatch(disposition)?.group(1) ??
        RegExp(
          r'filename\s*=\s*([^;]+)',
          caseSensitive: false,
        ).firstMatch(disposition)?.group(1);
    final safe = name?.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]'),
      '_',
    );
    return safe == null || safe.isEmpty || safe == '.' || safe == '..'
        ? null
        : safe;
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
