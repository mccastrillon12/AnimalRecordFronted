import 'dart:typed_data';

import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/data/services/medical_document_response_logger.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
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

  test('loads the Spanish field catalog for the selected category', () async {
    when(
      () => apiClient.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: _fieldCatalogResponse,
        requestOptions: RequestOptions(
          path: '/medical-documents/field-catalog',
        ),
        statusCode: 200,
      ),
    );

    final catalog = await dataSource.getFieldCatalog(
      category: MedicalDocumentCategory.clinicalHistory,
      locale: 'es-CO',
    );

    verify(
      () => apiClient.get<Map<String, dynamic>>(
        '/medical-documents/field-catalog',
        queryParameters: {'category': 'CLINICAL_HISTORY', 'locale': 'es-CO'},
      ),
    ).called(1);
    expect(catalog.categoryLabel, 'Historia clínica');
    expect(catalog.fieldAt('patient.identifier')?.label, 'Identificador');
  });

  test('loads the rejection reasons used by the review dropdown', () async {
    when(() => apiClient.get<List<dynamic>>(any())).thenAnswer(
      (_) async => Response<List<dynamic>>(
        data: const [
          {
            'code': 'INCORRECT_INFORMATION',
            'label': 'Información incorrecta',
            'requiresComment': false,
          },
          {'code': 'OTHER', 'label': 'Otros', 'requiresComment': true},
        ],
        requestOptions: RequestOptions(
          path: '/medical-documents/rejection-reasons',
        ),
        statusCode: 200,
      ),
    );

    final reasons = await dataSource.getRejectionReasons();

    verify(
      () =>
          apiClient.get<List<dynamic>>('/medical-documents/rejection-reasons'),
    ).called(1);
    expect(reasons.map((reason) => reason.code), [
      'INCORRECT_INFORMATION',
      'OTHER',
    ]);
    expect(reasons.last.requiresComment, isTrue);
    verify(
      () => responseLogger.logResponse(
        operation: 'REJECTION_REASONS',
        statusCode: 200,
        response: any(named: 'response'),
      ),
    ).called(1);
  });

  test(
    'submits LIKE and DISLIKE using the backend feedback contract',
    () async {
      when(
        () => apiClient.post<Object?>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response<Object?>(
          data: const {'count': 1},
          requestOptions: RequestOptions(
            path: '/medical-documents/ai-feedback',
          ),
          statusCode: 201,
        ),
      );

      await dataSource.submitAiFeedback(MedicalDocumentAiFeedback.like);
      await dataSource.submitAiFeedback(MedicalDocumentAiFeedback.dislike);

      verify(
        () => apiClient.post<Object?>(
          '/medical-documents/ai-feedback',
          data: {'value': 'LIKE'},
        ),
      ).called(1);
      verify(
        () => apiClient.post<Object?>(
          '/medical-documents/ai-feedback',
          data: {'value': 'DISLIKE'},
        ),
      ).called(1);
      verify(
        () => responseLogger.logResponse(
          operation: 'AI_FEEDBACK',
          statusCode: 201,
          response: any(named: 'response'),
        ),
      ).called(2);
    },
  );

  test('rejects an analyze response that does not use HTTP 202', () async {
    when(
      () =>
          apiClient.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: _response(status: 'ANALYZING'),
        requestOptions: RequestOptions(path: '/medical-documents/analyze'),
        statusCode: 200,
      ),
    );

    final future = dataSource.analyze(
      AnalyzeMedicalDocumentRequest(
        file: SharedFileEntity(
          path: '',
          name: 'formula.pdf',
          mimeType: 'application/pdf',
          type: SharedFileType.pdf,
          size: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        animalIds: const ['animal-1'],
      ),
    );

    await expectLater(future, throwsA(isA<FormatException>()));
  });

  test(
    'loads every accepted document and filters the category locally',
    () async {
      when(() => apiClient.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response<List<dynamic>>(
          data: [
            _acceptedDocument(
              id: 'vaccination-1',
              category: MedicalDocumentCategory.vaccinationCard,
            ),
            _acceptedDocument(
              id: 'vaccination-2',
              category: MedicalDocumentCategory.vaccinationCard,
            ),
            _acceptedDocument(
              id: 'prescription-1',
              category: MedicalDocumentCategory.prescription,
            ),
          ],
          requestOptions: RequestOptions(
            path: '/animals/animal-1/medical-documents',
          ),
          statusCode: 200,
        ),
      );

      final result = await dataSource.getByAnimal(
        'animal-1',
        category: MedicalDocumentCategory.vaccinationCard,
      );

      verify(
        () =>
            apiClient.get<List<dynamic>>('/animals/animal-1/medical-documents'),
      ).called(1);
      verify(
        () => responseLogger.logResponse(
          operation: 'LIST_BY_ANIMAL',
          statusCode: 200,
          response: any(named: 'response'),
        ),
      ).called(1);
      expect(result.map((document) => document.id), [
        'vaccination-1',
        'vaccination-2',
      ]);
    },
  );

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

  test('rejects a malformed original download URL', () async {
    when(() => apiClient.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: {'downloadUrl': '/relative/original.pdf'},
        requestOptions: RequestOptions(
          path: '/medical-documents/document-1/download-url',
        ),
      ),
    );

    await expectLater(
      dataSource.getDownloadUri('document-1'),
      throwsA(isA<FormatException>()),
    );
  });
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

const _fieldCatalogResponse = <String, dynamic>{
  'catalogVersion': '1.0.0',
  'locale': 'es-CO',
  'category': 'CLINICAL_HISTORY',
  'categoryLabel': 'Historia clínica',
  'sections': [
    {'key': 'patient', 'label': 'Paciente', 'order': 10},
  ],
  'fields': [
    {
      'path': 'patient.identifier',
      'label': 'Identificador',
      'sectionKey': 'patient',
      'order': 10,
      'kind': 'TEXT',
      'editable': true,
      'hideWhenEmpty': true,
    },
  ],
  'hiddenTechnicalKeys': ['id', 'confidence', 'source'],
};

Map<String, dynamic> _acceptedDocument({
  required String id,
  required MedicalDocumentCategory category,
}) => {
  ..._response(status: 'ACCEPTED'),
  'id': id,
  'finalCategory': category.wireValue,
  'validatedExtraction': {
    'documentType': category.wireValue,
    if (category == MedicalDocumentCategory.vaccinationCard)
      'vaccinations': [
        {'id': '$id-item', 'name': 'Rabia'},
      ],
  },
};
