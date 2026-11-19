import 'dart:async';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

const _history = AnimalOwnershipHistory(
  periodId: 'period-1',
  publicationHash: 'hash-1',
);
const _page = TransferPage<HistoricalEntry>([
  HistoricalEntry(
    entryId: 'animal',
    kind: 'ANIMAL',
    data: {
      'id': 'animal-1',
      'name': 'Luna',
      'species': 'EQUINE',
      'sex': 'FEMALE',
    },
    media: [],
  ),
  HistoricalEntry(
    entryId: 'note',
    kind: 'DIARY_ENTRY',
    data: {'title': 'Nota anterior', 'content': 'Contenido guardado'},
    media: [],
  ),
], null);

void main() {
  test(
    'ficha, diario y documentos simultáneos comparten una sola publicación',
    () async {
      final repository = _Repository();
      final response = Completer<TransferPage<HistoricalEntry>>();
      when(
        () => repository.getHistory('period-1', 'hash-1'),
      ).thenAnswer((_) => response.future);
      final shared = AnimalHistoryCache(repository);
      final card = AnimalDataModel.fromJson({
        'id': 'animal-1',
        'name': 'Luna',
        'species': 'EQUINE',
        'sex': 'FEMALE',
        'transferStatus': 'TRANSFERRED',
      }, historicalContext: _history);
      final animal = LoadHistoricalAnimalUseCase(shared)(
        card,
        includeEntries: false,
      );
      final diary = GetHistoricalDiaryUseCase(shared)(_history);
      final documents = GetHistoricalDocumentsUseCase(shared)(_history);
      response.complete(_page);
      expect((await animal).ownershipHistory!.entries, isNull);
      expect((await diary).single.content, 'Contenido guardado');
      expect(await documents, isEmpty);
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test(
    'los expedientes grandes se devuelven sin retenerlos sobre el presupuesto',
    () async {
      final repository = _Repository();
      when(
        () => repository.getHistory(any(), any()),
      ).thenAnswer((_) async => _page);
      final cache = AnimalHistoryCache(repository, maxEntries: 1, maxBytes: 1);
      expect((await cache.load(_history)).isLoaded, isTrue);
      expect(cache.peek(_history), isNull);
      await cache.load(_history);
      verify(() => repository.getHistory('period-1', 'hash-1')).called(2);
    },
  );
}
