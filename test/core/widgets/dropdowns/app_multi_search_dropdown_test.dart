import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closes after selecting when closeOnSelection is enabled', (
    tester,
  ) async {
    List<String> selected = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMultiSearchDropdown<String>(
            label: 'Temperamento',
            hint: 'Seleccionar',
            selectedItems: const [],
            items: const ['Calmado', 'Juguetón'],
            itemAsString: (item) => item,
            searchable: false,
            isInline: true,
            closeOnSelection: true,
            onChanged: (items) => selected = items,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    await tester.tap(find.text('Calmado'));
    await tester.pumpAndSettle();

    expect(selected, ['Calmado']);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
  });
}
