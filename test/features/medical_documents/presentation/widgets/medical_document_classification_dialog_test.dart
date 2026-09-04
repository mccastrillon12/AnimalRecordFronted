import 'dart:async';

import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_classification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows every detected category while keeping a single final selection',
    (tester) async {
      MedicalDocumentCategory? result;
      const document = MedicalDocumentEntity(
        id: 'multiple-document',
        animalIds: ['animal-1'],
        originalFileName: 'historia-y-vacunas.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        status: MedicalDocumentStatus.reviewPending,
        primaryDetectedCategory: MedicalDocumentCategory.clinicalHistory,
        detectedCategories: [
          DetectedMedicalDocumentCategoryEntity(
            category: MedicalDocumentCategory.clinicalHistory,
          ),
          DetectedMedicalDocumentCategoryEntity(
            category: MedicalDocumentCategory.vaccinationCard,
          ),
        ],
        classificationOutcome: MedicalDocumentClassificationOutcome.multiple,
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  unawaited(
                    showMedicalDocumentClassificationDialog(
                      context: context,
                      document: document,
                      initialCategory: MedicalDocumentCategory.clinicalHistory,
                    ).then((value) => result = value),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Historia clínica y Carné de vacunas.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      final dropdown = tester.widget<AppDropdown<MedicalDocumentCategory>>(
        find.byType(AppDropdown<MedicalDocumentCategory>),
      );
      expect(dropdown.value, MedicalDocumentCategory.clinicalHistory);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(result, MedicalDocumentCategory.clinicalHistory);
    },
  );

  testWidgets('requires an explicit selection when the file is unidentified', (
    tester,
  ) async {
    MedicalDocumentCategory? result;
    const document = MedicalDocumentEntity(
      id: 'unidentified-document',
      animalIds: ['animal-1'],
      originalFileName: 'archivo.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      primaryDetectedCategory: MedicalDocumentCategory.other,
      detectedCategories: [
        DetectedMedicalDocumentCategoryEntity(
          category: MedicalDocumentCategory.other,
        ),
      ],
      classificationOutcome: MedicalDocumentClassificationOutcome.unclassified,
      version: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentClassificationDialog(
                    context: context,
                    document: document,
                    initialCategory: MedicalDocumentCategory.other,
                  ).then((value) => result = value),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Archivo no identificado.', findRichText: true),
      findsOneWidget,
    );
    final dropdown = tester.widget<AppDropdown<MedicalDocumentCategory>>(
      find.byType(AppDropdown<MedicalDocumentCategory>),
    );
    expect(dropdown.value, isNull);
    expect(dropdown.hint, 'Tipo de contenido');
    expect(dropdown.items, isNot(contains(MedicalDocumentCategory.other)));
    expect(
      dropdown.items,
      orderedEquals(const [
        MedicalDocumentCategory.vaccinationCard,
        MedicalDocumentCategory.prescription,
        MedicalDocumentCategory.clinicalHistory,
        MedicalDocumentCategory.diagnosticImage,
        MedicalDocumentCategory.medicalOrder,
        MedicalDocumentCategory.referral,
        MedicalDocumentCategory.laboratoryResult,
      ]),
    );

    ElevatedButton continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    expect(continueButton.onPressed, isNull);

    dropdown.onChanged?.call(MedicalDocumentCategory.laboratoryResult);
    await tester.pump();

    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(result, MedicalDocumentCategory.laboratoryResult);
  });

  testWidgets('asks before cancelling the process from the close icon', (
    tester,
  ) async {
    var cancellationConfirmed = false;
    const document = MedicalDocumentEntity(
      id: 'document-to-cancel',
      animalIds: ['animal-1'],
      originalFileName: 'formula.pdf',
      mimeType: 'application/pdf',
      fileSize: 100,
      status: MedicalDocumentStatus.reviewPending,
      primaryDetectedCategory: MedicalDocumentCategory.prescription,
      classificationOutcome: MedicalDocumentClassificationOutcome.match,
      version: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentClassificationDialog(
                    context: context,
                    document: document,
                    initialCategory: MedicalDocumentCategory.prescription,
                    onProcessCancellationConfirmed: () {
                      cancellationConfirmed = true;
                    },
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('¿Desea cancelar el proceso?'), findsOneWidget);
    expect(
      find.text('Perderá los datos diligenciados al momento.'),
      findsOneWidget,
    );

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Análisis de archivo adjunto'), findsOneWidget);
    expect(cancellationConfirmed, isFalse);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Si'));
    await tester.pumpAndSettle();

    expect(cancellationConfirmed, isTrue);
    expect(find.text('Análisis de archivo adjunto'), findsNothing);
  });
}
