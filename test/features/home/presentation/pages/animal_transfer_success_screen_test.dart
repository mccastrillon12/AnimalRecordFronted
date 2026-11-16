import 'dart:async';

import 'package:animal_record/features/home/presentation/pages/animal_transfer_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _illustration = 'assets/illustrations/add-friend-on-social-media.svg';

class _DeferredIllustrationBundle extends CachingAssetBundle {
  final picture = Completer<ByteData>();

  @override
  Future<ByteData> load(String key) =>
      key == _illustration ? picture.future : rootBundle.load(key);
}

void main() {
  testWidgets(
    'reserves the illustration area until the bundled SVG is loaded',
    (tester) async {
    tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = await rootBundle.load(_illustration);
      final bundle = _DeferredIllustrationBundle();
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: bundle,
            child: AnimalTransferSuccessScreen(
              recipientName: 'Bárbara James',
              onFinish: () {},
            ),
          ),
        ),
      );
      final illustration = find.byKey(
        const Key('transfer-success-illustration'),
      );
      final title = find.text('Transferencia exitosa');
      expect(tester.getSize(illustration), const Size(283, 283));
      final before = tester.getTopLeft(title);
      expect(
        before.dy,
        greaterThanOrEqualTo(tester.getBottomLeft(illustration).dy + 24),
      );
      bundle.picture.complete(data);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(title), before);
      expect(tester.getSize(illustration), const Size(283, 283));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps Finish visible while long text scrolls on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AnimalTransferSuccessScreen(
          recipientName: 'Bárbara James con un nombre largo',
          onFinish: () => finished = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final finish = find.byKey(const Key('transfer-finish'));
    expect(tester.getRect(finish).bottom, lessThanOrEqualTo(640));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(finish);
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
