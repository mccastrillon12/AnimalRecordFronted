import 'package:animal_record/features/home/presentation/widgets/animal_filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closes the age dropdown after selecting an option', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.9)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAnimalFilterModal(context),
              child: const Text('Abrir filtros'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir filtros'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Selecciona rango de edad'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('7-11 meses'), findsOneWidget);

    await tester.tap(find.text('0-6 meses'));
    await tester.pumpAndSettle();

    expect(find.text('0-6 meses'), findsOneWidget);
    expect(find.text('7-11 meses'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
