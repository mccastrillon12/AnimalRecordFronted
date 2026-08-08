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
          originalUrl: 'https://example.test/original',
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
    expect(find.text('Observación variable del backend.'), findsOneWidget);
    expect(find.text('Subir documento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final dateLabel = tester.widget<Text>(find.text('Fecha'));
    final medicationName = tester.widget<Text>(
      find.text('Medicamento variable'),
    );
    final originalFileName = tester.widget<Text>(
      find.text('resultado-variable.pdf'),
    );
    expect(dateLabel.style?.fontSize, AppTypography.body4.fontSize);
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
        'Análisis realizado con IA. Verifica los datos antes de subir el archivo; una vez enviado, no se admiten cambios ni eliminaciones.',
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
    expect(analysis.medications.single.originalUrl, 'document-id');
  });
}
