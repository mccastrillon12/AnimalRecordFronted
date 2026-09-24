import 'dart:async';

import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_rejection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _reasons = [
  MedicalDocumentRejectionReasonEntity(
    code: 'INCORRECT_INFORMATION',
    label: 'Información incorrecta',
    requiresComment: false,
  ),
  MedicalDocumentRejectionReasonEntity(
    code: 'WRONG_ANIMAL',
    label: 'El archivo no es el correspondiente al animal',
    requiresComment: false,
  ),
  MedicalDocumentRejectionReasonEntity(
    code: 'OTHER',
    label: 'Otros',
    requiresComment: true,
  ),
];

void main() {
  testWidgets('loads reasons from the backend before retrying', (tester) async {
    MedicalDocumentRejectionSelection? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentRejectionDialog(
                    context: context,
                    loadReasons: () async => _reasons,
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

    expect(find.text('¿Qué estuvo mal?'), findsOneWidget);
    expect(
      find.text('Seleccionar el motivo:', findRichText: true),
      findsOneWidget,
    );
    final dropdown = tester
        .widget<AppDropdown<MedicalDocumentRejectionReasonEntity>>(
          find.byType(AppDropdown<MedicalDocumentRejectionReasonEntity>),
        );
    expect(dropdown.items, _reasons);

    await tester.tap(find.text('Motivo'));
    await tester.pumpAndSettle();
    expect(find.text('Información incorrecta'), findsOneWidget);
    expect(
      find.text('El archivo no es el correspondiente al animal'),
      findsOneWidget,
    );
    expect(find.text('Otros'), findsOneWidget);

    await tester.tap(find.text('Información incorrecta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(result?.reason.code, 'INCORRECT_INFORMATION');
    expect(result?.comment, isNull);
  });

  testWidgets('requires a comment when the backend reason requests it', (
    tester,
  ) async {
    MedicalDocumentRejectionSelection? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentRejectionDialog(
                    context: context,
                    loadReasons: () async => _reasons,
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
    await tester.tap(find.text('Motivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rejection-reason-comment')), findsOneWidget);
    var confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reintentar'),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byType(TextFormField),
      'La imagen está borrosa',
    );
    await tester.pump();
    confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reintentar'),
    );
    expect(confirmButton.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(result?.reason.code, 'OTHER');
    expect(result?.comment, 'La imagen está borrosa');
  });

  testWidgets('reports an explicit cancellation from the Cancelar button', (
    tester,
  ) async {
    var wasCancelled = false;
    var dialogFutureCompleted = false;
    final cancellation = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentRejectionDialog(
                    context: context,
                    loadReasons: () async => _reasons,
                    onCancel: () async {
                      wasCancelled = true;
                      await cancellation.future;
                    },
                  ).then((_) => dialogFutureCompleted = true),
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
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(wasCancelled, isTrue);
    expect(find.text('¿Qué estuvo mal?'), findsNothing);
    expect(dialogFutureCompleted, isFalse);

    cancellation.complete();
    await tester.pumpAndSettle();

    expect(dialogFutureCompleted, isTrue);
  });
}
