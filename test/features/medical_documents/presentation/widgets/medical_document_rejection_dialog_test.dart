import 'dart:async';

import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_rejection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires one of the configured reasons before retrying', (
    tester,
  ) async {
    MedicalDocumentRejectionReason? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  showMedicalDocumentRejectionDialog(
                    context: context,
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
    expect(find.text('Motivo'), findsOneWidget);
    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reintentar'),
    );
    expect(confirmButton.onPressed, isNull);

    final dropdown = tester.widget<AppDropdown<MedicalDocumentRejectionReason>>(
      find.byType(AppDropdown<MedicalDocumentRejectionReason>),
    );
    expect(dropdown.items, MedicalDocumentRejectionReason.values);

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
    final enabledConfirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reintentar'),
    );
    expect(enabledConfirmButton.onPressed, isNotNull);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(result, MedicalDocumentRejectionReason.incorrectInformation);
  });
}
