import 'dart:typed_data';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:dio/dio.dart';

/// Servicio para subir archivos directamente a S3 usando Pre-signed URLs.
/// Usa un Dio independiente SIN interceptores de autenticación,
/// ya que S3 rechaza peticiones que incluyan el header Authorization de JWT.
class S3UploadService implements FileUploader {
  final Dio _dio;

  S3UploadService() : _dio = Dio();

  /// Sube [bytes] directamente a la [presignedUrl] generada por el backend.
  /// El [mimeType] debe coincidir con el usado al generar la URL (e.g. 'image/jpeg').
  Future<void> uploadFileToS3({
    required String presignedUrl,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return upload(uploadUrl: presignedUrl, bytes: bytes, mimeType: mimeType);
  }

  @override
  Future<void> upload({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await _dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {'Content-Type': mimeType, 'Content-Length': bytes.length},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
  }
}
