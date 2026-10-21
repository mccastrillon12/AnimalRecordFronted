import 'dart:typed_data';

import 'package:animal_record/features/shared_files/data/datasources/shared_file_export_datasource.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_image_pdf_converter.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_merger.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';

class _MockPdfBuilder extends Mock implements SharedFilePdfBuilder {}

class _MockSharePlus extends Mock implements SharePlus {}

class _MockDio extends Mock implements Dio {}

class _MockPdfMerger extends Mock implements SharedFilePdfMerger {}

class _MockImagePdfConverter extends Mock
    implements SharedFileImagePdfConverter {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const analysis = SharedFileAnalysisEntity(
    documentType: 'Imagen diagnóstica',
    documentNumber: '',
    date: null,
    originalFileName: 'informe.pdf',
    patient: SharedFilePatientAnalysisEntity(
      name: '',
      recordId: '',
      species: '',
      breed: '',
      age: '',
      weight: '',
    ),
    tutor: SharedFileTutorAnalysisEntity(
      name: '',
      identification: '',
      phoneNumber: '',
    ),
  );
  setUpAll(() {
    registerFallbackValue(ShareParams(text: 'Documento'));
    registerFallbackValue(Options());
  });

  for (final status in ShareResultStatus.values) {
    test(
      'reports successful sharing only for success, received $status',
      () async {
        final builder = _MockPdfBuilder();
        final share = _MockSharePlus();
        when(
          () => builder.build(
            analysis: analysis,
            logoBytes: any(named: 'logoBytes'),
          ),
        ).thenAnswer((_) async => Uint8List.fromList([37, 80, 68, 70]));
        when(
          () => share.share(any()),
        ).thenAnswer((_) async => ShareResult('', status));
        final datasource = SharedFileExportDataSourceImpl(
          pdfBuilder: builder,
          sharePlus: share,
        );

        expect(
          await datasource.exportAnalysisPdf(analysis),
          status == ShareResultStatus.success,
        );
        final params =
            verify(() => share.share(captureAny())).captured.single
                as ShareParams;
        expect(params.files, hasLength(1));
        expect(params.fileNameOverrides, ['imagen_diagnóstica.pdf']);
      },
    );
  }

  test('appends an image original after the Animal Record PDF', () async {
    final builder = _MockPdfBuilder();
    final share = _MockSharePlus();
    final dio = _MockDio();
    final merger = _MockPdfMerger();
    final converter = _MockImagePdfConverter();
    final summaryBytes = Uint8List.fromList([37, 80, 68, 70, 1]);
    final imageBytes = Uint8List.fromList([137, 80, 78, 71]);
    final imagePdfBytes = Uint8List.fromList([37, 80, 68, 70, 2]);
    final combinedBytes = Uint8List.fromList([37, 80, 68, 70, 3]);
    final imageAnalysis = SharedFileAnalysisEntity(
      documentType: analysis.documentType,
      documentNumber: analysis.documentNumber,
      date: analysis.date,
      originalFileName: 'informe.png',
      originalMimeType: 'image/png',
      patient: analysis.patient,
      tutor: analysis.tutor,
      originalUrl: 'https://example.test/informe',
    );
    when(
      () => builder.build(
        analysis: imageAnalysis,
        logoBytes: any(named: 'logoBytes'),
      ),
    ).thenAnswer((_) async => summaryBytes);
    when(
      () => dio.get<List<int>>(
        'https://example.test/informe',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<List<int>>(
        data: imageBytes,
        requestOptions: RequestOptions(path: '/informe'),
      ),
    );
    when(
      () => converter.convert(imageBytes),
    ).thenAnswer((_) async => imagePdfBytes);
    when(() => merger.merge(any())).thenAnswer((_) async => combinedBytes);
    when(
      () => share.share(any()),
    ).thenAnswer((_) async => const ShareResult('', ShareResultStatus.success));

    final datasource = SharedFileExportDataSourceImpl(
      pdfBuilder: builder,
      sharePlus: share,
      dio: dio,
      pdfMerger: merger,
      imagePdfConverter: converter,
    );

    expect(await datasource.exportAnalysisPdf(imageAnalysis), isTrue);
    final documents =
        verify(() => merger.merge(captureAny())).captured.single
            as List<Uint8List>;
    expect(documents, [summaryBytes, imagePdfBytes]);
  });
}
