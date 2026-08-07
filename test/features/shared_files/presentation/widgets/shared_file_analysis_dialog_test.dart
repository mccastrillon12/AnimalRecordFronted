import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/shared_file_analysis_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('allows changing the detected content type before continuing', (
    tester,
  ) async {
    SharedFileContentType? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                unawaited(
                  showSharedFileAnalysisDialog(context: context).then((value) {
                    result = value;
                  }),
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

    expect(find.text('Análisis de archivo adjunto'), findsOneWidget);
    expect(find.text('IA'), findsOneWidget);
    expect(find.text('Tipo de contenido', findRichText: true), findsOneWidget);
    expect(find.text('Fórmula médica'), findsOneWidget);

    final dropdown = tester.widget<AppDropdown<SharedFileContentType>>(
      find.byType(AppDropdown<SharedFileContentType>),
    );
    expect(dropdown.isInline, isTrue);
    expect(dropdown.pushContent, isTrue);

    final magicStar = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(magicStar.width, 18);
    expect(magicStar.height, 18);
    final indicatorPosition = tester.widget<Positioned>(
      find.ancestor(
        of: find.byType(SvgPicture),
        matching: find.byType(Positioned),
      ),
    );
    expect(indicatorPosition.left, 16);
    expect(indicatorPosition.top, 16);

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    expect(
      continueButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.aiViolet,
    );

    await tester.tap(find.text('Fórmula médica'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orden médica'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(result, SharedFileContentType.medicalOrder);
    expect(find.text('Análisis de archivo adjunto'), findsNothing);
  });

  testWidgets('returns null when the dialog is cancelled', (tester) async {
    SharedFileContentType? result = SharedFileContentType.medicalOrder;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                unawaited(
                  showSharedFileAnalysisDialog(context: context).then((value) {
                    result = value;
                  }),
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

    expect(result, isNull);
  });
}
