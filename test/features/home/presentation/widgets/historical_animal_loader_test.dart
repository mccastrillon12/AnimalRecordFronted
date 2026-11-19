import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/historical_animal_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

void main() {
  testWidgets(
    'volver a abrir muestra los datos en el primer frame sin recarga ni otra consulta',
    (tester) async {
      final repository = _Repository();
      when(() => repository.getHistory('period-1', 'hash-1')).thenAnswer(
        (_) async => const TransferPage([
          HistoricalEntry(
            entryId: 'entry-1',
            kind: 'ANIMAL',
            data: {
              'name': 'Luna guardada',
              'species': 'EQUINE',
              'sex': 'FEMALE',
              'weight': 350,
            },
            media: [],
          ),
        ], null),
      );
      di.sl.registerSingleton(
        LoadHistoricalAnimalUseCase(
          AnimalHistoryCache(repository)..useAccount('owner-1'),
        ),
      );
      addTearDown(() => di.sl.unregister<LoadHistoricalAnimalUseCase>());
      Widget screen() => MaterialApp(
        home: HistoricalAnimalLoader(
          animal: const AnimalModel(
            id: 'animal-1',
            name: 'Luna',
            code: 'AR-E018',
            family: 'Equino',
            transferStatus: 'TRANSFERRED',
            readOnly: true,
            ownershipHistory: AnimalOwnershipHistory(
              periodId: 'period-1',
              publicationHash: 'hash-1',
            ),
          ),
          builder: (animal) =>
              Scaffold(body: Text('${animal.name}: ${animal.weight}')),
        ),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Luna Guardada: 350.0'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      expect(find.text('Luna Guardada: 350.0'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verifyNoMoreInteractions(repository);
    },
  );
}
