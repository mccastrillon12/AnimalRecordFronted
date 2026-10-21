import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const spacerKey = Key('keyboard-spacer');

  Widget buildSubject({required double keyboardInset}) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: KeyboardSpacer(
            key: spacerKey,
            keyboardVisibleHeight: 20,
            keyboardHiddenHeight: 40,
          ),
        ),
      ),
    );
  }

  testWidgets('limita el espacio inferior a 20 px con teclado abierto', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(keyboardInset: 320));

    expect(tester.getSize(find.byKey(spacerKey)).height, 20);
  });

  testWidgets('mantiene 40 px cuando el teclado está cerrado', (tester) async {
    await tester.pumpWidget(buildSubject(keyboardInset: 0));

    expect(tester.getSize(find.byKey(spacerKey)).height, 40);
  });
}
