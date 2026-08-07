import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
        age: '4 años',
        weight: '6 kg',
      ),
      tutor: const SharedFileTutorAnalysisEntity(
        name: 'Tutor variable',
        identification: 'C.C. 900001',
        phoneNumber: '(+57) 300 000 00 00',
      ),
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
}
