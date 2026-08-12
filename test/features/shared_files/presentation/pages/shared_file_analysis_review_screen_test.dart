import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_state.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSharedFilesCubit extends Mock implements SharedFilesCubit {}

void main() {
  testWidgets('shows an original link for every clinical content section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var originalOpened = false;
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Historia clínica',
      documentNumber: 'HC-1',
      date: null,
      originalFileName: 'historia.pdf',
      patient: SharedFilePatientAnalysisEntity(
        name: 'Chuleta',
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
      sections: [
        SharedFileAnalysisSectionEntity(
          title: 'Diagnóstico',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'clinicalFindings',
              value: 'Masa axilar',
            ),
          ],
        ),
        SharedFileAnalysisSectionEntity(
          title: 'Historia clínica',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'treatmentPlan',
              value: 'Control en 5 días',
            ),
          ],
        ),
        SharedFileAnalysisSectionEntity(
          title: 'Información adicional',
          body:
              'Clinical history returned by backend\n'
              'Owner reports patient does not seem sedated',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SharedFileAnalysisReviewScreen(
          analysis: analysis,
          onViewOriginal: () => originalOpened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver original'), findsNWidgets(3));
    expect(
      find.textContaining('Clinical history returned by backend'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Owner reports patient does not seem sedated'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Ver original').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver original').last);
    expect(originalOpened, isTrue);
  });

  testWidgets('shows the no-upload action and invokes its callback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var doNotUploadPressed = false;
    const analysis = SharedFileAnalysisEntity(
      documentType: 'Carné de vacunas',
      documentNumber: '',
      date: null,
      originalFileName: 'vacunas.pdf',
      patient: SharedFilePatientAnalysisEntity(
        name: 'Canela',
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

    await tester.pumpWidget(
      MaterialApp(
        home: SharedFileAnalysisReviewScreen(
          analysis: analysis,
          onDoNotUpload: () => doNotUploadPressed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subir documento'), findsOneWidget);
    expect(find.text('No subir'), findsOneWidget);

    await tester.tap(find.text('No subir'));

    expect(doNotUploadPressed, isTrue);
  });

  testWidgets('renders every value received through the analysis entity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final analysis = SharedFileAnalysisEntity(
      documentType: 'Orden veterinaria variable',
      documentNumber: 'DOC-987',
      date: DateTime(2027, 3, 14),
      originalFileName: 'resultado-variable.pdf',
      patient: const SharedFilePatientAnalysisEntity(
        name: 'Paciente variable',
        recordId: 'AR-999',
        species: 'Felino',
        breed: 'Criollo',
        sex: 'Macho',
        color: 'Blanco y negro',
        age: '4 años',
        weight: '6 kg',
        additionalDetails: [
          SharedFileAnalysisDetailEntity(
            label: 'Microchip',
            value: '985141000000001',
          ),
        ],
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: 'Tutor variable',
        identification: 'C.C. 900001',
        phoneNumber: '(+57) 300 000 00 00',
        additionalDetails: [
          SharedFileAnalysisDetailEntity(
            label: 'Correo electrónico',
            value: 'tutor@example.com',
          ),
        ],
      ),
      veterinarian: const SharedFileVeterinarianAnalysisEntity(
        name: 'Dra. Natalia López',
        clinic: 'Clínica variable',
        professionalId: 'MV-41611',
      ),
      itemsTitle: 'Medicamentos',
      medications: const [
        SharedFileMedicationAnalysisEntity(
          name: 'Medicamento variable',
          quantity: 3,
          instructions: 'Indicaciones variables del backend.',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'backendKey',
              value: 'backendValue',
            ),
          ],
          originalUrl: 'https://example.test/original',
        ),
      ],
      sections: const [
        SharedFileAnalysisSectionEntity(
          title: 'Remisión',
          details: [
            SharedFileAnalysisDetailEntity(
              label: 'Motivo',
              value: 'Evaluación cardiológica',
            ),
            SharedFileAnalysisDetailEntity(
              label: 'Destino',
              value: 'Clínica Cardiovet',
            ),
          ],
        ),
      ],
      observations: 'Observación variable del backend.',
    );

    await tester.pumpWidget(
      MaterialApp(home: SharedFileAnalysisReviewScreen(analysis: analysis)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ModalPageLayout), findsOneWidget);
    expect(find.text('Orden veterinaria variable'), findsOneWidget);
    expect(find.text('DOC-987'), findsOneWidget);
    expect(find.text('Marzo 14, 2027'), findsOneWidget);
    expect(find.text('resultado-variable.pdf'), findsOneWidget);
    expect(
      find.textContaining('Paciente variable', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('AR-999'), findsOneWidget);
    expect(find.text('Macho'), findsOneWidget);
    expect(find.text('Blanco y negro'), findsOneWidget);
    expect(find.text('985141000000001'), findsOneWidget);
    expect(
      find.textContaining('Tutor variable', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('tutor@example.com'), findsOneWidget);
    expect(
      find.textContaining('Dra. Natalia López', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Clínica variable'), findsOneWidget);
    expect(find.text('MV-41611'), findsOneWidget);
    expect(find.text('Medicamentos'), findsOneWidget);
    expect(find.text('Medicamento variable'), findsOneWidget);
    expect(find.text('x 3'), findsOneWidget);
    expect(find.text('Indicaciones variables del backend.'), findsOneWidget);
    expect(find.text('backendKey'), findsOneWidget);
    expect(find.text('backendValue'), findsOneWidget);
    expect(find.text('Remisión'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
    expect(find.text('Evaluación cardiológica'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Clínica Cardiovet'), findsOneWidget);
    expect(find.text('Observación variable del backend.'), findsOneWidget);
    expect(find.text('Subir documento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final dateLabel = tester.widget<Text>(find.text('Fecha'));
    final dynamicLabel = tester.widget<Text>(find.text('backendKey'));
    final medicationName = tester.widget<Text>(
      find.text('Medicamento variable'),
    );
    final originalFileName = tester.widget<Text>(
      find.text('resultado-variable.pdf'),
    );
    expect(dateLabel.style?.fontSize, AppTypography.body4.fontSize);
    final multiWordLabel = tester.widget<Text>(find.text('Animal Record ID'));
    expect(dynamicLabel.maxLines, 1);
    expect(dynamicLabel.overflow, TextOverflow.ellipsis);
    expect(multiWordLabel.maxLines, 2);
    expect(multiWordLabel.overflow, TextOverflow.ellipsis);
    expect(medicationName.style?.fontSize, AppTypography.body4.fontSize);
    expect(originalFileName.maxLines, 1);
    expect(originalFileName.overflow, TextOverflow.ellipsis);

    final patientIdRow = tester.widget<Row>(
      find
          .ancestor(
            of: find.text('Animal Record ID'),
            matching: find.byType(Row),
          )
          .first,
    );
    expect(patientIdRow.children[1], isA<SizedBox>());
    expect((patientIdRow.children[1] as SizedBox).width, AppSpacing.xs);

    await tester.drag(
      find.text('resultado-variable.pdf'),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Análisis realizado con IA. Verifica los datos antes de subir el '
        'archivo; una vez enviado, no se admiten cambios ni eliminaciones. Si '
        'seleccionó múltiples animales este será el documento que se le '
        'asociará a cada uno de ellos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Subir documento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final gradientContainers = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).gradient ==
                AppColors.aiAnalysisGradient,
      ),
    );
    expect(gradientContainers.length, greaterThanOrEqualTo(2));
    expect(
      gradientContainers.any(
        (container) => container.padding == const EdgeInsets.all(16),
      ),
      isTrue,
    );
    final layout = tester.widget<ModalPageLayout>(find.byType(ModalPageLayout));
    expect(layout.fixedHeaderHeight, greaterThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the send page with export action and tutor data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final analysis = SharedFileAnalysisEntity(
      documentType: 'Fórmula médica',
      documentNumber: 'N° 11230',
      date: DateTime(2026, 1, 25),
      originalFileName: 'formula.pdf',
      patient: const SharedFilePatientAnalysisEntity(
        name: 'Brownie',
        recordId: 'AR-C012',
        species: 'Canino',
        breed: 'Labrador',
        age: '10 años',
        weight: '15 kg',
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: 'Barbara James',
        identification: 'C.C. 1152234567',
        phoneNumber: '(+57) 312 456 78 90',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/shared-file-send': (_) => SharedFileSendScreen(analysis: analysis),
        },
        home: SharedFileAnalysisReviewScreen(analysis: analysis),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subir documento'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar fórmula'), findsOneWidget);
    expect(
      find.textContaining('Verifica siempre', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Barbara James', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('C.C. 1152234567'), findsOneWidget);
    expect(find.text('(+57) 312 456 78 90'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render labels for fields omitted by backend', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const analysis = SharedFileAnalysisEntity(
      documentType: 'Fórmula médica',
      documentNumber: 'N° 60366a51',
      date: null,
      originalFileName: 'formula.pdf',
      patient: SharedFilePatientAnalysisEntity(
        name: 'BENJI',
        recordId: 'AR-B017',
        species: 'Felino',
        breed: 'Persa',
        age: '',
        weight: '',
      ),
      tutor: SharedFileTutorAnalysisEntity(
        name: '',
        identification: '',
        phoneNumber: '',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SharedFileAnalysisReviewScreen(analysis: analysis),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('BENJI', findRichText: true), findsOneWidget);
    expect(find.text('Animal Record ID'), findsOneWidget);
    expect(find.text('Especie'), findsOneWidget);
    expect(find.text('Raza'), findsOneWidget);
    expect(find.text('Edad'), findsNothing);
    expect(find.text('Peso'), findsNothing);
    expect(find.text('Fecha'), findsNothing);
    expect(find.textContaining('Tutor', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the export action label supplied by the document tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const analysis = SharedFileAnalysisEntity(
      documentType: 'Orden médica',
      documentNumber: 'N° 123',
      date: null,
      originalFileName: 'orden.pdf',
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

    await tester.pumpWidget(
      const MaterialApp(
        home: SharedFileSendScreen(
          analysis: analysis,
          actionLabel: 'Enviar orden',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enviar orden'), findsOneWidget);
    expect(find.text('Enviar fórmula'), findsNothing);
    expect(
      tester.getCenter(find.text('Enviar orden')).dy,
      closeTo(tester.getCenter(find.byIcon(Icons.close)).dy, 0.5),
    );
  });

  testWidgets('resolves and injects the original URL before exporting', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const analysis = SharedFileAnalysisEntity(
      documentType: 'Fórmula médica',
      documentNumber: 'N° 123',
      date: null,
      originalFileName: 'formula.pdf',
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
      medications: [
        SharedFileMedicationAnalysisEntity(
          name: 'Medicamento',
          instructions: 'Cada 12 horas',
          originalUrl: 'document-id',
        ),
      ],
    );
    registerFallbackValue(analysis);
    final cubit = _MockSharedFilesCubit();
    when(() => cubit.state).thenReturn(SharedFilesInitial());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.exportAnalysisPdf(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<SharedFilesCubit>.value(
        value: cubit,
        child: MaterialApp(
          home: SharedFileSendScreen(
            analysis: analysis,
            resolveOriginalUri: () async =>
                Uri.parse('https://api.example.test/original/document-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar fórmula'));
    await tester.pumpAndSettle();

    final exported =
        verify(() => cubit.exportAnalysisPdf(captureAny())).captured.single
            as SharedFileAnalysisEntity;
    expect(
      exported.medications.single.originalUrl,
      'https://api.example.test/original/document-1',
    );
    expect(
      exported.originalUrl,
      'https://api.example.test/original/document-1',
    );
    expect(analysis.medications.single.originalUrl, 'document-id');
    expect(analysis.originalUrl, isNull);
  });
}
