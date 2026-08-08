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
}
