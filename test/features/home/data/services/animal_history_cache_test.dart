import 'dart:async';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

const _history = AnimalOwnershipHistory(
  periodId: 'period-1',
  publicationHash: 'hash-1',
);
const _page = TransferPage<HistoricalEntry>([
  HistoricalEntry(
    entryId: 'animal-1',
    kind: 'ANIMAL',
    data: {'name': 'Luna'},
    media: [],
  ),
], null);

void main() {
  test(
    'precarga y apertura comparten la consulta y conservan la publicación completa',
    () async {
      final repository = _Repository();
      final response = Completer<TransferPage<HistoricalEntry>>();
      when(
        () => repository.getHistory('period-1', 'hash-1'),
      ).thenAnswer((_) => response.future);
      when(
        () => repository.getHistory('period-1', 'hash-1', cursor: 'page-2'),
      ).thenAnswer((_) async => const TransferPage([], null));
      final cache = AnimalHistoryCache(repository)..useAccount('owner-1');
      final prefetch = cache.load(_history);
      final open = cache.load(_history);
      response.complete(TransferPage(_page.items, 'page-2'));
      expect(await open, await prefetch);
      expect(cache.peek(_history)?.isLoaded, isTrue);
      expect(await cache.load(_history), cache.peek(_history));
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verify(
        () => repository.getHistory('period-1', 'hash-1', cursor: 'page-2'),
      ).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test('un fallo de precarga no impide reintentar al abrir la ficha', () async {
    final repository = _Repository();
    var requests = 0;
    when(() => repository.getHistory('period-1', 'hash-1')).thenAnswer((
      _,
    ) async {
      if (++requests == 1) throw StateError('Sin conexión');
      return _page;
    });
    final cache = AnimalHistoryCache(repository);
    await expectLater(cache.load(_history), throwsStateError);
    expect(cache.peek(_history), isNull);
    expect((await cache.load(_history)).isLoaded, isTrue);
    expect(requests, 2);
  });

  test(
    'otra publicación, cuenta o sesión no reutiliza el contenido anterior',
    () async {
      final repository = _Repository();
      when(
        () => repository.getHistory(any(), any()),
      ).thenAnswer((_) async => _page);
      final cache = AnimalHistoryCache(repository)..useAccount('owner-1');
      await cache.load(_history);
      const changed = AnimalOwnershipHistory(
        periodId: 'period-1',
        publicationHash: 'hash-2',
      );
      expect(cache.peek(changed), isNull);
      await cache.load(changed);
      cache.useAccount('owner-2');
      expect(cache.peek(_history), isNull);
      await cache.load(_history);
      cache.clear();
      expect(cache.peek(_history), isNull);
      verify(() => repository.getHistory('period-1', 'hash-1')).called(2);
      verify(() => repository.getHistory('period-1', 'hash-2')).called(1);
    },
  );

  test(
    'cambiar de cuenta descarta también todas las aperturas que estaban pendientes',
    () async {
      final repository = _Repository();
      final response = Completer<TransferPage<HistoricalEntry>>();
      when(
        () => repository.getHistory('period-1', 'hash-1'),
      ).thenAnswer((_) => response.future);
      final cache = AnimalHistoryCache(repository)..useAccount('owner-1');
      final first = expectLater(cache.load(_history), throwsStateError);
      final second = expectLater(cache.load(_history), throwsStateError);
      cache.useAccount('owner-2');
      response.complete(_page);
      await Future.wait([first, second]);
      expect(cache.peek(_history), isNull);
    },
  );
}
