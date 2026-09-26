import 'dart:typed_data';

import 'package:animal_record/features/shared_files/data/datasources/shared_file_export_datasource.dart';
import 'package:animal_record/features/shared_files/data/services/shared_file_pdf_builder.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';

class _MockPdfBuilder extends Mock implements SharedFilePdfBuilder {}

class _MockSharePlus extends Mock implements SharePlus {}

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
}
