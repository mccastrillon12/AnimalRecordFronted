import 'dart:async';

import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_animals_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TransferRepository extends Mock implements AnimalTransferRepository {}

class _AnimalCubit extends Mock implements AnimalCubit {}

void main() {
  for (final rejecting in [false, true]) {
    testWidgets(
      'conserva los botones tras un fallo al ${rejecting ? 'rechazar' : 'aceptar'}',
      (tester) async {
        final repository = _TransferRepository();
        const request = TransferRequest(
          id: 'transfer-1',
          status: 'PENDING',
          version: 1,
          recipientName: 'Receptor',
          animalCount: 1,
        );
        const item = TransferItem(
          id: 'item-1',
          animalId: 'animal-1',
          animalName: 'Animal',
          animalCode: 'AR-B010',
          status: 'PENDING',
        );
        when(() => repository.getDetail(request.id)).thenAnswer(
          (_) async =>
              const TransferDetail(request, TransferPage([item], null)),
        );
        final keys = <String>[];
        when(
          () => repository.decide(
            id: request.id,
            expectedVersion: request.version,
            acceptedAnimalIds: rejecting ? const [] : [item.animalId],
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenAnswer((invocation) async {
          keys.add(invocation.namedArguments[#idempotencyKey] as String);
          throw const ApiException(message: 'No disponible', statusCode: 503);
        });
        await tester.pumpWidget(
          MaterialApp(
            home: AnimalTransferDetailScreen(
              repository: repository,
              transferId: request.id,
              incoming: true,
              acceptanceLayout: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final accept = find.widgetWithText(CustomButton, 'Aceptar');
        final reject = find.widgetWithText(OutlinedButton, 'Rechazar');
        final originalAction = rejecting ? reject : accept;
        await tester.tap(originalAction);
        await tester.pumpAndSettle();
        if (rejecting) {
          await tester.tap(find.text('Seleccionar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Desconocimiento de transferencia'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sí'));
          await tester.pumpAndSettle();
        }

        expect(accept, findsOneWidget);
        expect(reject, findsOneWidget);
        expect(find.textContaining('Reintentar'), findsNothing);
        expect(
          tester.widget<CustomButton>(accept).onPressed != null,
          !rejecting,
        );
        expect(
          tester.widget<OutlinedButton>(reject).onPressed != null,
          rejecting,
        );
        expect(keys, hasLength(1));

        await tester.tap(originalAction);
        await tester.pumpAndSettle();
        expect(keys, [keys.first, keys.first]);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  }

  for (final count in [1, 2]) {
    testWidgets('acepta $count animal(es) y vuelve a Mis animales', (
      tester,
    ) async {
      final repository = _TransferRepository();
      final animals = _AnimalCubit();
      final refresh = Completer<void>();
      when(() => animals.stream).thenAnswer((_) => const Stream.empty());
      when(() => animals.currentOwnerId).thenReturn('owner-1');
      when(
        () => animals.loadAnimals('owner-1', forceRefresh: true),
      ).thenAnswer((_) => refresh.future);
      final items = List.generate(
        count,
        (index) => TransferItem(
          id: 'item-$index',
          animalId: 'animal-$index',
          animalName: 'Animal $index',
          animalCode: 'AR-B01$index',
          status: 'PENDING',
        ),
      );
      TransferRequest request(String status, int version) => TransferRequest(
        id: 'transfer-1',
        status: status,
        version: version,
        recipientName: 'Receptor',
        animalCount: count,
      );
      var current = request('PENDING', 1);
      final decision = Completer<TransferRequest>();
      when(() => repository.getDetail('transfer-1')).thenAnswer(
        (_) async => TransferDetail(current, TransferPage(items, null)),
      );
      when(
        () => repository.decide(
          id: 'transfer-1',
          expectedVersion: 1,
          acceptedAnimalIds: items.map((item) => item.animalId).toList(),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) => decision.future);

      await tester.pumpWidget(
        BlocProvider<AnimalCubit>.value(
          value: animals,
          child: MaterialApp(
            routes: {
              AppRoutes.home: (context) {
                expect(ModalRoute.of(context)?.settings.arguments, {
                  homeInitialSectionArgument: homeMyAnimalsSection,
                });
                return const Scaffold(body: Text('Mis animales'));
              },
            },
            home: AnimalTransferDetailScreen(
              repository: repository,
              transferId: 'transfer-1',
              incoming: true,
              acceptanceLayout: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final accept = find.widgetWithText(
        CustomButton,
        count == 1 ? 'Aceptar' : 'Aceptar todo',
      );
      final rows = find.byType(TransferAnimalSummaryRow);
      final acceptRect = tester.getRect(accept);
      final firstAnimalRect = tester.getRect(rows.first);
      void expectUnchangedTransfer() {
        expect(tester.getRect(accept), acceptRect);
        expect(tester.widget<CustomButton>(accept).onPressed, isNull);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(
                  OutlinedButton,
                  count == 1 ? 'Rechazar' : 'Rechazar seleccionados',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ModalBarrier &&
                !widget.dismissible &&
                widget.color == AppColors.overlayBlack,
          ),
          findsOneWidget,
        );
        expect(rows, findsNWidgets(count));
        expect(tester.getRect(rows.first), firstAnimalRect);
        expect(find.text('Traspaso en curso'), findsNothing);
        expect(find.text('Aceptado'), findsNothing);
      }

      await tester.tap(accept);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      final spinner = find.byWidgetPredicate(
        (widget) =>
            widget is CircularProgressIndicator &&
            widget.semanticsLabel == 'Cargando',
      );
      expect(spinner, findsOneWidget);
      expectUnchangedTransfer();
      expect(tester.getCenter(spinner), const Offset(400, 300));
      expect(find.byType(LinearProgressIndicator), findsNothing);

      current = request('PROCESSING', 2);
      decision.complete(current);
      await tester.pump();
      expect(spinner, findsOneWidget);
      expectUnchangedTransfer();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Mis animales'), findsNothing);
      verifyNever(() => animals.loadAnimals('owner-1', forceRefresh: true));

      current = request('ACCEPTED', 3);
      await tester.pump(const Duration(seconds: 5));
      verify(
        () => animals.loadAnimals('owner-1', forceRefresh: true),
      ).called(1);
      expect(spinner, findsOneWidget);
      expectUnchangedTransfer();
      expect(find.text('Mis animales'), findsNothing);
      refresh.complete();
      await tester.pumpAndSettle();
      expect(spinner, findsNothing);
      expect(find.text('Mis animales'), findsOneWidget);
      expect(
        find.text(
          count == 1
              ? 'Los animales han sido recibidos exitosamente. Visualícelos en la sección “Mis animales”'
              : 'Los animales seleccionados han sido recibidos exitosamente. Visualícelos en la sección “Mis animales”',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    });
  }

  testWidgets('rechazar seleccionados acepta solamente los demás', (
    tester,
  ) async {
    const pending = TransferRequest(
      id: 'transfer-1',
      status: 'PENDING',
      version: 1,
      recipientName: 'Receptor',
      senderName: 'John Doe',
      animalCount: 3,
    );
    const accepted = TransferRequest(
      id: 'transfer-1',
      status: 'PARTIALLY_ACCEPTED',
      version: 2,
      recipientName: 'Receptor',
      senderName: 'John Doe',
      animalCount: 3,
    );
    const items = [
      TransferItem(
        id: 'item-1',
        animalId: 'animal-1',
        animalName: 'Vaca 010',
        animalCode: 'AR-B010',
        status: 'PENDING',
      ),
      TransferItem(
        id: 'item-2',
        animalId: 'animal-2',
        animalName: 'Vaca 011',
        animalCode: 'AR-B011',
        status: 'PENDING',
      ),
      TransferItem(
        id: 'item-3',
        animalId: 'animal-3',
        animalName: 'Vaca 012',
        animalCode: 'AR-B012',
        status: 'PENDING',
      ),
    ];
    final repository = _TransferRepository();
    var detail = const TransferDetail(pending, TransferPage(items, null));
    when(
      () => repository.getDetail(pending.id),
    ).thenAnswer((_) async => detail);
    when(
      () => repository.decide(
        id: pending.id,
        expectedVersion: pending.version,
        acceptedAnimalIds: ['animal-2', 'animal-3'],
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {
      detail = const TransferDetail(accepted, TransferPage(items, null));
      return accepted;
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.home: (context) {
            expect(ModalRoute.of(context)?.settings.arguments, isNull);
            return const Scaffold(body: Text('Inicio'));
          },
        },
        home: AnimalTransferDetailScreen(
          repository: repository,
          transferId: pending.id,
          incoming: true,
          acceptanceLayout: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Animales a transferir (3)'), findsOneWidget);
    expect(find.byType(TransferAnimalSummaryRow), findsNWidgets(3));
    expect(find.text('Aceptar todo'), findsOneWidget);
    expect(find.text('Rechazar seleccionados'), findsOneWidget);
    final note = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan?.toPlainText().startsWith('Nota: ') == true,
    );
    expect(
      tester.widget<Text>(note).style?.fontSize,
      AppTypography.body6.fontSize,
    );
    expect(
      tester.getTopLeft(find.widgetWithText(CustomButton, 'Aceptar todo')).dy -
          tester.getBottomLeft(note).dy,
      32,
    );
    final acceptButton = find.widgetWithText(CustomButton, 'Aceptar todo');
    final rejectButton = find.widgetWithText(
      OutlinedButton,
      'Rechazar seleccionados',
    );
    final margin = tester.getTopLeft(note).dx;
    for (var index = 0; index < 4; index++) {
      expect(
        tester.getCenter(find.byType(Checkbox).at(index)).dx - 11,
        closeTo(margin, 0.01),
      );
    }
    expect(tester.getTopLeft(acceptButton).dx, margin);
    expect(tester.getTopLeft(rejectButton).dx, margin);
    final rejectStyle = tester.widget<OutlinedButton>(rejectButton).style!;
    expect(
      rejectStyle.side?.resolve({WidgetState.disabled})?.color,
      AppColors.greyBordes,
    );
    expect(
      rejectStyle.backgroundColor?.resolve({WidgetState.disabled}),
      AppColors.white,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Rechazar seleccionados'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.byType(TransferAnimalSummaryRow), findsNWidgets(3));
    expect(
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .every((checkbox) => checkbox.value == true),
      isTrue,
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('item-1')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Rechazar seleccionados'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Rechazar seleccionados'));
    await tester.pumpAndSettle();
    expect(find.text('¿Desea rechazar la transferencia?'), findsOneWidget);
    expect(
      find.textContaining('Los demás animales se aceptarán.'),
      findsOneWidget,
    );
    final yes = find.widgetWithText(ElevatedButton, 'Sí');
    expect(tester.widget<ElevatedButton>(yes).onPressed, isNull);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    verifyNever(
      () => repository.decide(
        id: any(named: 'id'),
        expectedVersion: any(named: 'expectedVersion'),
        acceptedAnimalIds: any(named: 'acceptedAnimalIds'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    );
    await tester.tap(find.text('Rechazar seleccionados'));
    await tester.pumpAndSettle();
    final title = find.text('¿Desea rechazar la transferencia?');
    final collapsedHeight =
        tester.getBottomLeft(yes).dy - tester.getTopLeft(title).dy;
    await tester.tap(find.text('Seleccionar'));
    await tester.pumpAndSettle();
    final reason = find.text('Desconocimiento de transferencia');
    expect(reason, findsOneWidget);
    expect(find.text('No tiene la responsabilidad o recursos'), findsOneWidget);
    final other = find.text('Otro');
    expect(other, findsOneWidget);
    final detailLabel = find.text('¿Cuál?', findRichText: true);
    expect(detailLabel, findsNothing);
    expect(
      tester.getBottomLeft(yes).dy - tester.getTopLeft(title).dy,
      greaterThan(collapsedHeight),
    );
    expect(
      tester.getBottomLeft(reason).dy,
      lessThan(tester.getTopLeft(yes).dy),
    );
    await tester.tap(other);
    await tester.pumpAndSettle();
    expect(detailLabel, findsOneWidget);
    expect(tester.widget<ElevatedButton>(yes).onPressed, isNull);
    final detailInput = find.descendant(
      of: find.byKey(const Key('transfer-rejection-reason-detail')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(detailInput, '   ');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(yes).onPressed, isNull);
    await tester.enterText(detailInput, 'No puedo recibir a este animal.');
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(yes).onPressed, isNotNull);
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
    expect(
      find.text(
        'Los animales han sido rechazados. El usuario John Doe será notificado.',
      ),
      findsOneWidget,
    );
    verify(
      () => repository.decide(
        id: pending.id,
        expectedVersion: pending.version,
        acceptedAnimalIds: ['animal-2', 'animal-3'],
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
    await tester.pump(const Duration(seconds: 4));
  });
}
