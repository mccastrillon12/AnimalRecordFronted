import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_acceptance_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

void main() {
  const request = TransferRequest(
    id: 'transfer-1',
    status: 'PENDING',
    version: 1,
    recipientName: 'Receptor',
    animalCount: 1,
  );
  const detail = TransferDetail(
    request,
    TransferPage([
      TransferItem(
        id: 'item-1',
        animalId: 'animal-1',
        animalName: 'Umi',
        animalCode: 'AR-F038',
        status: 'PENDING',
      ),
    ], null),
  );

  Finder loadingBarrier() => find.byWidgetPredicate(
    (widget) =>
        widget is ModalBarrier &&
        !widget.dismissible &&
        widget.color == AppColors.overlayBlack,
  );

  Widget screen(AnimalTransferRepository repository) => MaterialApp(
    home: AnimalTransferDetailScreen(
      repository: repository,
      transferId: request.id,
      incoming: true,
      acceptanceLayout: true,
    ),
  );

  testWidgets(
    'initial loading uses the shared dark barrier and releases it when complete',
    (tester) async {
      final repository = _Repository();
      final response = Completer<TransferDetail>();
      when(
        () => repository.getDetail(request.id),
      ).thenAnswer((_) => response.future);
      await tester.pumpWidget(screen(repository));
      await tester.pump();
      expect(loadingBarrier(), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete(detail);
      await tester.pumpAndSettle();
      expect(loadingBarrier(), findsNothing);
      expect(
        tester
            .widget<CustomButton>(find.widgetWithText(CustomButton, 'Aceptar'))
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Rechazar'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'refresh disables both actions without changing the visible transfer',
    (tester) async {
      final repository = _Repository();
      when(
        () => repository.getDetail(request.id),
      ).thenAnswer((_) async => detail);
      await tester.pumpWidget(screen(repository));
      await tester.pumpAndSettle();
      final accept = find.widgetWithText(CustomButton, 'Aceptar');
      final reject = find.widgetWithText(OutlinedButton, 'Rechazar');
      final acceptRect = tester.getRect(accept);
      final response = Completer<TransferDetail>();
      when(
        () => repository.getDetail(request.id),
      ).thenAnswer((_) => response.future);
      final cubit = tester
          .element(find.byType(TransferAcceptanceView))
          .read<TransferDetailCubit>();
      final refresh = cubit.refresh();
      await tester.pump();
      await tester.pump();
      expect(cubit.state.loading, isTrue);
      expect(
        tester
            .widget<TransferAcceptanceView>(find.byType(TransferAcceptanceView))
            .loading,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(loadingBarrier(), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getRect(accept), acceptRect);
      expect(tester.widget<CustomButton>(accept).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(reject).onPressed, isNull);
      await tester.tap(accept, warnIfMissed: false);
      await tester.pump();
      verifyNever(
        () => repository.decide(
          id: any(named: 'id'),
          expectedVersion: any(named: 'expectedVersion'),
          acceptedAnimalIds: any(named: 'acceptedAnimalIds'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      response.complete(detail);
      await refresh;
      await tester.pumpAndSettle();
      expect(loadingBarrier(), findsNothing);
      expect(tester.widget<CustomButton>(accept).onPressed, isNotNull);
      expect(tester.widget<OutlinedButton>(reject).onPressed, isNotNull);
    },
  );

  testWidgets(
    'a failed initial load removes the barrier so the user can retry',
    (tester) async {
      final repository = _Repository();
      final response = Completer<TransferDetail>();
      when(
        () => repository.getDetail(request.id),
      ).thenAnswer((_) => response.future);
      await tester.pumpWidget(screen(repository));
      await tester.pump();
      expect(loadingBarrier(), findsOneWidget);
      response.completeError(
        const ApiException(message: 'No disponible', statusCode: 503),
      );
      await tester.pumpAndSettle();
      expect(loadingBarrier(), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Reintentar'))
            .onPressed,
        isNotNull,
      );
    },
  );
}
