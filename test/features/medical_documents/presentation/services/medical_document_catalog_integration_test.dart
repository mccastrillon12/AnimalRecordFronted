import 'dart:convert';

import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/data/repositories/medical_documents_repository_impl.dart';
import 'package:animal_record/features/medical_documents/data/services/medical_document_response_logger.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockResponseLogger extends Mock
    implements MedicalDocumentResponseLogger {}

class _MockDocumentsCubit extends Mock implements AnimalMedicalDocumentsCubit {}

void main() {
  late _MockApiClient apiClient;
  late MedicalDocumentAnalysisPresenter presenter;
  late MedicalDocumentsRepositoryImpl repository;

  final narrative = List.generate(
    40,
    (index) => 'Hallazgo ${index + 1}. Medida 3.58 cm.',
  ).join('\n');
  // Preserve the current visual line breaks, including decimal measurements.
  final displayedNarrative = List.generate(
    40,
    (index) => 'Hallazgo ${index + 1}.\nMedida 3.58 cm.',
  ).join('\n');

  setUp(() {
    apiClient = _MockApiClient();
    when(
      () => apiClient.get<Map<String, dynamic>>(
        '/medical-documents/field-catalog',
        queryParameters: {'category': 'DIAGNOSTIC_IMAGE', 'locale': 'es-CO'},
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: _diagnosticCatalog(),
        requestOptions: RequestOptions(
          path: '/medical-documents/field-catalog',
        ),
        statusCode: 200,
      ),
    );
    repository = MedicalDocumentsRepositoryImpl(
      remoteDataSource: MedicalDocumentsRemoteDataSourceImpl(
        apiClient: apiClient,
        responseLogger: _MockResponseLogger(),
      ),
    );
    presenter = MedicalDocumentAnalysisPresenter(
      getFieldCatalog: GetMedicalFieldCatalogUseCase(repository),
    );
  });

  testWidgets(
    'review stays read-only and visually unchanged after a local JSON round trip',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final document = _document(narrative);
      final extraction = document.validatedExtraction!;
      final restored = MedicalDocumentModel.extractionFromJson(
        jsonDecode(
              jsonEncode(MedicalDocumentModel.extractionToJson(extraction)),
            )
            as Map<String, dynamic>,
        MedicalDocumentCategory.diagnosticImage,
      );
      final before = await presenter.forReview(
        document: document,
        extraction: extraction,
        finalCategory: MedicalDocumentCategory.laboratoryResult,
      );
      final after = await presenter.forReview(
        document: document,
        extraction: restored,
        finalCategory: MedicalDocumentCategory.laboratoryResult,
      );
      expect(after, before);
      expect(restored.diagnosticImages.single.reportedFindings, narrative);
      expect(restored.documentType, MedicalDocumentCategory.diagnosticImage);
      expect(restored.laboratoryResults, isEmpty);

      await tester.pumpWidget(
        MaterialApp(home: SharedFileAnalysisReviewScreen(analysis: after)),
      );
      await tester.pumpAndSettle();
      _expectCompleteReadOnlyNarrative(tester, displayedNarrative);
      await tester.ensureVisible(find.text('Conclusión escrita'));
      await tester.pumpAndSettle();
      expect(find.text('Conclusión escrita').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      _verifyDiagnosticCatalogRequest(apiClient);
    },
  );

  testWidgets(
    'laboratory archive opens diagnostic detail with catalog 1.2.0 and full text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      di.sl.registerSingleton<MedicalDocumentAnalysisPresenter>(presenter);
      addTearDown(() => di.sl.unregister<MedicalDocumentAnalysisPresenter>());
      final document = _document(narrative);
      final cubit = _MockDocumentsCubit();
      when(() => cubit.state).thenReturn(
        AnimalMedicalDocumentsLoaded([
          document,
        ], category: MedicalDocumentCategory.laboratoryResult),
      );
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        BlocProvider<AnimalMedicalDocumentsCubit>.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(
              body: AnimalMedicalDocumentsView(
                animalId: 'animal-1',
                category: MedicalDocumentCategory.laboratoryResult,
                emptyTitle: 'Sin documentos',
                emptyDescription: 'Sin documentos',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('medical-document-detail-diagnostic-document')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SharedFileSendScreen), findsOneWidget);
      expect(find.text('Resultados de laboratorio'), findsOneWidget);
      _expectCompleteReadOnlyNarrative(tester, displayedNarrative);
      await tester.ensureVisible(find.text('Diagnóstico rotulado'));
      await tester.pumpAndSettle();
      expect(find.text('Diagnóstico rotulado').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final cached = await repository.getFieldCatalog(
        category: MedicalDocumentCategory.diagnosticImage,
      );
      expect(cached.catalogVersion, '1.2.0');
      _verifyDiagnosticCatalogRequest(apiClient);
    },
  );
}

void _verifyDiagnosticCatalogRequest(_MockApiClient apiClient) {
  verify(
    () => apiClient.get<Map<String, dynamic>>(
      '/medical-documents/field-catalog',
      queryParameters: {'category': 'DIAGNOSTIC_IMAGE', 'locale': 'es-CO'},
    ),
  ).called(1);
  verifyNoMoreInteractions(apiClient);
}

void _expectCompleteReadOnlyNarrative(WidgetTester tester, String narrative) {
  final findings = find.text(narrative);
  expect(findings, findsOneWidget);
  final text = tester.widget<Text>(findings);
  expect(text.maxLines, isNull);
  expect(text.overflow, isNull);
  expect(tester.getSize(findings).height, greaterThan(844));
  expect(find.text('Resumen escrito'), findsOneWidget);
  expect(find.text('Control posterior.\nHome care: reposo.'), findsOneWidget);
  expect(find.text('Resumen generado'), findsNothing);
  expect(find.text('Observaciones'), findsNothing);
  expect(find.text('Informe original'), findsNothing);
  expect(find.byType(EditableText), findsNothing);
  expect(find.byType(TextField), findsNothing);
  expect(find.byType(TextFormField), findsNothing);
}

MedicalDocumentModel _document(String narrative) =>
    MedicalDocumentModel.fromJson({
      'id': 'diagnostic-document',
      'animalIds': ['animal-1'],
      'originalFileName': 'ecografia.pdf',
      'mimeType': 'application/pdf',
      'fileSize': 100,
      'status': 'ACCEPTED',
      'finalCategory': 'LABORATORY_RESULT',
      'version': 2,
      'validatedExtraction': {
        'documentType': 'DIAGNOSTIC_IMAGE',
        'summary': 'Resumen generado',
        'reportedSummary': 'Resumen escrito',
        'reportedRecommendations': 'Control posterior. Home care: reposo.',
        'reportedObservations': '',
        'diagnosticImages': [
          {
            'id': 'image-1',
            'name': 'Ecografía abdominal',
            'reportedTechnique': 'Sonda de 9 MHz',
            'reportedFindings': narrative,
            'reportedConclusion': 'Conclusión escrita',
            'reportedDiagnosis': 'Diagnóstico rotulado',
            'confidence': 0.91,
            'source': {
              'page': 1,
              'text': 'Informe original',
              'boundingBox': [1, 2, 3, 4],
            },
          },
        ],
      },
    });

Map<String, dynamic> _diagnosticCatalog() => {
  'catalogVersion': '1.2.0',
  'locale': 'es-CO',
  'category': 'DIAGNOSTIC_IMAGE',
  'categoryLabel': 'Imagen diagnóstica',
  'sections': [
    {'key': 'report', 'label': 'Informe', 'order': 1},
  ],
  'fields': [
    for (final (index, path, label) in [
      (0, 'summary', 'Resumen anterior'),
      (1, 'reportedSummary', 'Resumen'),
      (2, 'reportedRecommendations', 'Recomendaciones'),
      (3, 'reportedObservations', 'Observaciones'),
    ])
      {
        'path': path,
        'label': label,
        'sectionKey': 'report',
        'order': index,
        'kind': 'LONG_TEXT',
        'editable': true,
        'hideWhenEmpty': false,
      },
    {
      'path': 'diagnosticImages',
      'label': 'Imágenes diagnósticas',
      'sectionKey': 'report',
      'order': 4,
      'kind': 'TABLE',
      'editable': true,
      'columns': [
        for (final (index, key, label) in [
          (0, 'name', 'Nombre'),
          (1, 'reportedTechnique', 'Técnica'),
          (2, 'reportedFindings', 'Hallazgos'),
          (3, 'reportedConclusion', 'Conclusión'),
          (4, 'reportedDiagnosis', 'Diagnóstico'),
        ])
          {
            'key': key,
            'label': label,
            'order': index,
            'kind': 'LONG_TEXT',
            'editable': true,
            'hideWhenEmpty': true,
          },
      ],
    },
  ],
  'hiddenTechnicalKeys': ['id', 'confidence', 'source'],
};
