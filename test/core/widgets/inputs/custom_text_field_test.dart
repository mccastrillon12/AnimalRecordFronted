import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the suffix visible after entering a value', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: '',
            hint: '- kg',
            suffixText: 'kg',
            suffixTextWhenNotEmpty: true,
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('- kg'), findsOneWidget);
    expect(find.text('kg'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '10');
    await tester.pump();

    expect(controller.text, '10');
    expect(find.text('kg'), findsOneWidget);
    final suffix = tester.widget<Text>(find.text('kg'));
    expect(suffix.style?.color, AppColors.greyBordes);

    controller.clear();
    await tester.pump();
    expect(find.text('kg'), findsNothing);

    controller.text = '22,05';
    await tester.pump();
    expect(find.text('kg'), findsOneWidget);
  });
}
