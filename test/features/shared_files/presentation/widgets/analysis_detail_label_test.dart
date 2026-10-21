import 'package:animal_record/features/shared_files/presentation/widgets/analysis_detail_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Text> renderLabel(
    WidgetTester tester,
    String label, {
    double scale = 1,
    double width = 119,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Center(
            child: SizedBox(
              width: width,
              child: AnalysisDetailLabel(label: label, width: width),
            ),
          ),
        ),
      ),
    );
    return tester.widget<Text>(
      find.descendant(
        of: find.byType(AnalysisDetailLabel),
        matching: find.byType(Text),
      ),
    );
  }

  testWidgets('wraps long labels beyond two lines', (tester) async {
    const label =
        'Resumen reportado en el informe de imágenes diagnósticas del paciente';
    final text = await renderLabel(tester, label);
    expect(text.maxLines, isNull);
    expect(text.data!.split('\n').length, greaterThan(2));
    expect(text.semanticsLabel, label);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the final complete word on a new line', (tester) async {
    final text = await renderLabel(
      tester,
      'Resumen reportado en el informe',
      width: 160,
    );
    expect(text.data!.replaceAll('\n', ' '), 'Resumen reportado en el informe');
    expect(text.data, contains('\n'));
    expect(text.data, isNot(contains('...')));
    expect(text.semanticsLabel, 'Resumen reportado en el informe');
  });

  testWidgets('does not wrap the trailing letters of an oversized word', (
    tester,
  ) async {
    final text = await renderLabel(
      tester,
      'Recomendaciones reportadas',
      width: 160,
    );
    expect(text.data!.split('\n').first, endsWith('...'));
    expect(text.data!.split('\n').last, 'reportadas');
    expect(text.data!.split('\n'), isNot(contains('s reportadas')));
    expect(text.softWrap, isFalse);
  });

  for (final label in [
    'Hallazgos reportados',
    'Técnica reportada',
    'Fecha del estudio',
    'Región corporal',
    'Número de acceso',
  ]) {
    testWidgets('shows the complete label on multiple lines: $label', (
      tester,
    ) async {
      // The test font is monospaced and wider than the app's Noto Sans.
      final text = await renderLabel(tester, label, width: 160);
      expect(text.data, contains('\n'));
      expect(text.data!.replaceAll('\n', ' '), label);
      expect(text.maxLines, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('measures labels with the accessibility text scale', (
    tester,
  ) async {
    const label =
        'Resumen reportado en el informe de imágenes diagnósticas del paciente';
    final normal = await renderLabel(tester, label);
    final enlarged = await renderLabel(tester, label, scale: 1.5);
    expect(
      enlarged.data!.split('\n').length,
      greaterThanOrEqualTo(normal.data!.split('\n').length),
    );
    expect(enlarged.data, isNot(normal.data));
    expect(enlarged.semanticsLabel, label);
    expect(tester.takeException(), isNull);
  });
}
