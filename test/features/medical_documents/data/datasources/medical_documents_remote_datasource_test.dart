import 'dart:typed_data';

import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/data/services/medical_document_response_logger.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockMedicalDocumentResponseLogger extends Mock
    implements MedicalDocumentResponseLogger {}

void main() {
  late _MockApiClient apiClient;
  late _MockMedicalDocumentResponseLogger responseLogger;
  late MedicalDocumentsRemoteDataSourceImpl dataSource;

  setUp(() {
    apiClient = _MockApiClient();
    responseLogger = _MockMedicalDocumentResponseLogger();
    dataSource = MedicalDocumentsRemoteDataSourceImpl(
      apiClient: apiClient,
      responseLogger: responseLogger,
    );
  });

  test(
    'uploads bytes with the multipart contract expected by the backend',
    () async {
      when(
        () => apiClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: _response(status: 'ANALYZING'),
          requestOptions: RequestOptions(path: '/medical-documents/analyze'),
          statusCode: 202,
        ),
      );

      final result = await dataSource.analyze(
        AnalyzeMedicalDocumentRequest(
          file: SharedFileEntity(
            path: '',
            name: 'formula.pdf',
            mimeType: 'application/pdf',
            type: SharedFileType.pdf,
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
          animalIds: const ['animal-1', 'animal-2'],
          requestedCategory: MedicalDocumentCategory.prescription,
        ),
      );

      final captured =
          verify(
                () => apiClient.post<Map<String, dynamic>>(
                  '/medical-documents/analyze',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      final fields = {
        for (final field in captured.fields) field.key: field.value,
      };
      expect(fields['animalIds'], '["animal-1","animal-2"]');
      expect(fields['requestedCategory'], 'PRESCRIPTION');
      expect(captured.files.single.key, 'file');
      expect(captured.files.single.value.filename, 'formula.pdf');
      expect(result.status, MedicalDocumentStatus.analyzing);
      verify(
        () => responseLogger.logResponse(
          operation: 'ANALYZE',
          statusCode: 202,
          response: any(named: 'response'),
        ),
      ).called(1);
    },
  );

  test('logs every complete polling response after analysis', () async {
    when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: _response(status: 'REVIEW_PENDING'),
        requestOptions: RequestOptions(path: '/medical-documents/document-1'),
        statusCode: 200,
      ),
    );

    await dataSource.getById('document-1');
    await dataSource.getById('document-1');

    verify(
      () => responseLogger.logResponse(
        operation: 'ANALYSIS_STATUS',
        statusCode: 200,
        response: any(named: 'response'),
      ),
    ).called(2);
  });

  test('lists accepted documents using the final-category query', () async {
    when(
      () => apiClient.get<List<dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        data: [_response(status: 'ACCEPTED')],
        requestOptions: RequestOptions(
          path: '/animals/animal-1/medical-documents',
        ),
      ),
    );

    final result = await dataSource.getByAnimal(
      'animal-1',
      category: MedicalDocumentCategory.vaccinationCard,
    );

    verify(
      () => apiClient.get<List<dynamic>>(
        '/animals/animal-1/medical-documents',
        queryParameters: {'category': 'VACCINATION_CARD'},
      ),
    ).called(1);
    expect(result.single.status, MedicalDocumentStatus.accepted);
  });

  test(
    'requests a fresh signed URL every time the original is opened',
    () async {
      when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {'downloadUrl': 'https://example.test/original?signature=new'},
          requestOptions: RequestOptions(
            path: '/medical-documents/document-1/download-url',
          ),
        ),
      );

      final first = await dataSource.getDownloadUri('document-1');
      final second = await dataSource.getDownloadUri('document-1');

      expect(first.queryParameters['signature'], 'new');
      expect(second, first);
      verify(
        () => apiClient.get<Map<String, dynamic>>(
          '/medical-documents/document-1/download-url',
        ),
      ).called(2);
    },
  );
}

Map<String, dynamic> _response({required String status}) => {
  'id': 'document-1',
  'animalIds': ['animal-1', 'animal-2'],
  'originalFileName': 'formula.pdf',
  'mimeType': 'application/pdf',
  'fileSize': 3,
  'status': status,
  'detectedCategories': [],
  'extractionsByCategory': {},
  'assignments': [],
  'version': 1,
};
