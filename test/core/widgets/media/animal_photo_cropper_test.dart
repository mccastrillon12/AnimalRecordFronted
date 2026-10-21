import 'dart:io';

import 'package:animal_record/core/widgets/media/animal_photo_cropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra un unico encuadre 2:1 con control de zoom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final imageFile = File('assets/Logo/logo-app-cropped.png').absolute;

    await tester.pumpWidget(
      MaterialApp(home: AnimalPhotoCropper(imagePath: imageFile.path)),
    );
    final viewport = find.byKey(const Key('animal-photo-crop-viewport'));
    for (
      var attempt = 0;
      attempt < 20 && viewport.evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(viewport, findsOneWidget);
    final viewportSize = tester.getSize(viewport);
    expect(
      viewportSize.width / viewportSize.height,
      moreOrLessEquals(animalPhotoAspectRatio),
    );
    expect(find.byKey(const Key('animal-photo-crop-zoom')), findsOneWidget);
    expect(find.byKey(const Key('animal-photo-crop-save')), findsOneWidget);
    expect(
      find.text('Mueve y amplía la foto para llenar el encuadre'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
