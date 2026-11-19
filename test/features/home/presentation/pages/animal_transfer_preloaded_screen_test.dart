import 'package:animal_record/features/home/data/services/incoming_transfer_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_animals_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

void main() {
  testWidgets(
    'la solicitud preparada en Home se ve desde el primer frame y al reabrir',
    (tester) async {
      const request = TransferRequest(
        id: 'transfer-1',
        status: 'PENDING',
        version: 1,
        recipientName: 'Receptor',
        senderName: 'Remitente',
        animalCount: 1,
      );
      const item = TransferItem(
        id: 'item-1',
        animalId: 'animal-1',
        animalName: 'Luna',
        animalCode: 'AR-E018',
        status: 'PENDING',
      );
      final repository = _Repository();
      when(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).thenAnswer((_) async => const TransferPage([request], null));
      when(() => repository.getDetail(request.id)).thenAnswer(
        (_) async => const TransferDetail(request, TransferPage([item], null)),
      );
      final cache = IncomingTransferCache(repository);
      await cache.refreshPending();
      await cache.prefetchPending();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Widget screen() => MaterialApp(
        home: AnimalTransferRequestsScreen(
          repository: repository,
          previewCache: cache,
          focusPending: true,
        ),
      );
      await tester.pumpWidget(screen());
      expect(find.byType(TransferAnimalSummaryRow), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      expect(find.byType(TransferAnimalSummaryRow), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      verify(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).called(1);
      verify(() => repository.getDetail(request.id)).called(1);
      verifyNoMoreInteractions(repository);
      expect(tester.takeException(), isNull);
    },
  );
}
