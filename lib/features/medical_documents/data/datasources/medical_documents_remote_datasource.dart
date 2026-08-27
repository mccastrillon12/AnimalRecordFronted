import 'dart:convert';

import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/data/services/medical_document_response_logger.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:dio/dio.dart';

abstract interface class MedicalDocumentsRemoteDataSource {
  Future<MedicalDocumentModel> analyze(AnalyzeMedicalDocumentRequest request);

  Future<MedicalDocumentModel> getById(String documentId);

  Future<List<MedicalDocumentRejectionReasonEntity>> getRejectionReasons();

  Future<void> submitAiFeedback(MedicalDocumentAiFeedback feedback);

  Future<MedicalDocumentModel> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  );

  Future<List<MedicalDocumentModel>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  });

  Future<Uri> getDownloadUri(String documentId);
}

class MedicalDocumentsRemoteDataSourceImpl
    implements MedicalDocumentsRemoteDataSource {
  final ApiClient apiClient;
  final MedicalDocumentResponseLogger responseLogger;

  const MedicalDocumentsRemoteDataSourceImpl({
    required this.apiClient,
    required this.responseLogger,
  });

  @override
  Future<MedicalDocumentModel> analyze(
    AnalyzeMedicalDocumentRequest request,
  ) async {
    final file = request.file;
    final multipartFile = file.bytes != null && file.bytes!.isNotEmpty
        ? MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
            contentType: DioMediaType.parse(file.mimeType),
          )
        : await MultipartFile.fromFile(
            file.path,
            filename: file.name,
            contentType: DioMediaType.parse(file.mimeType),
          );
    final formData = FormData.fromMap({
      'file': multipartFile,
      'animalIds': jsonEncode(request.animalIds),
      if (request.requestedCategory != null)
        'requestedCategory': request.requestedCategory!.wireValue,
    });
    final response = await apiClient.post<Map<String, dynamic>>(
      '/medical-documents/analyze',
      data: formData,
    );
    responseLogger.logResponse(
      operation: 'ANALYZE',
      statusCode: response.statusCode,
      response: response.data,
    );
    if (response.statusCode != 202) {
      throw FormatException(
        'El análisis debía iniciar con HTTP 202, pero respondió '
        '${response.statusCode ?? 'sin estado'}.',
      );
    }
    return MedicalDocumentModel.fromJson(_responseMap(response.data));
  }

  @override
  Future<MedicalDocumentModel> getById(String documentId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/medical-documents/$documentId',
    );
    responseLogger.logResponse(
      operation: 'ANALYSIS_STATUS',
      statusCode: response.statusCode,
      response: response.data,
    );
    return MedicalDocumentModel.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<MedicalDocumentRejectionReasonEntity>>
  getRejectionReasons() async {
    final response = await apiClient.get<List<dynamic>>(
      '/medical-documents/rejection-reasons',
    );
    responseLogger.logResponse(
      operation: 'REJECTION_REASONS',
      statusCode: response.statusCode,
      response: response.data,
    );
    return (response.data ?? const [])
        .map((item) {
          final json = _responseMap(item);
          final code = json['code']?.toString().trim() ?? '';
          final label = json['label']?.toString().trim() ?? '';
          if (code.isEmpty || label.isEmpty) {
            throw const FormatException(
              'El servidor devolvió un motivo de rechazo inválido.',
            );
          }
          return MedicalDocumentRejectionReasonEntity(
            code: code,
            label: label,
            requiresComment: json['requiresComment'] == true,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> submitAiFeedback(MedicalDocumentAiFeedback feedback) async {
    final response = await apiClient.post<Object?>(
      '/medical-documents/ai-feedback',
      data: {'value': feedback.wireValue},
    );
    responseLogger.logResponse(
      operation: 'AI_FEEDBACK',
      statusCode: response.statusCode,
      response: response.data,
    );
  }

  @override
  Future<MedicalDocumentModel> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) async {
    final response = await apiClient.put<Map<String, dynamic>>(
      '/medical-documents/$documentId/review',
      data: MedicalDocumentModel.reviewRequestToJson(request),
    );
    responseLogger.logResponse(
      operation: 'REVIEW',
      statusCode: response.statusCode,
      response: response.data,
    );
    return MedicalDocumentModel.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<MedicalDocumentModel>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  }) async {
    final response = await apiClient.get<List<dynamic>>(
      '/animals/$animalId/medical-documents',
    );
    responseLogger.logResponse(
      operation: 'LIST_BY_ANIMAL',
      statusCode: response.statusCode,
      response: response.data,
    );
    final documents = (response.data ?? const [])
        .map((item) => MedicalDocumentModel.fromJson(_responseMap(item)))
        .toList(growable: false);
    if (category == null) return documents;
    return documents
        .where(
          (document) =>
              document.finalCategory == category ||
              document.validatedExtraction?.documentType == category,
        )
        .toList(growable: false);
  }

  @override
  Future<Uri> getDownloadUri(String documentId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/medical-documents/$documentId/download-url',
    );
    final value = _responseMap(response.data)['downloadUrl']?.toString();
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      throw const FormatException('El servidor no devolvió una URL válida.');
    }
    return uri;
  }

  Map<String, dynamic> _responseMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('Respuesta de archivos médicos inválida.');
  }
}
