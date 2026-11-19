import 'dart:async';
import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/data/services/incoming_transfer_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_home_notice_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AnimalTransferRepository {}

const request = TransferRequest(
  id: 'transfer-1',
  status: 'PENDING',
  version: 3,
  recipientName: 'Receptor',
  animalCount: 2,
);
const first = TransferItem(
  id: 'item-1',
  animalId: 'animal-1',
  animalName: 'Luna',
  animalCode: 'AR-E018',
  status: 'PENDING',
);
const second = TransferItem(
  id: 'item-2',
  animalId: 'animal-2',
  animalName: 'Sol',
  animalCode: 'AR-C002',
  status: 'PENDING',
  animalImageUrl: 'https://example.com/photo?Signature=old',
);

void main() {
  late _Repository repository;
  setUp(() {
    repository = _Repository();
    when(
      () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
    ).thenAnswer((_) async => const TransferPage([request], null));
    when(() => repository.getDetail(request.id)).thenAnswer(
      (_) async =>
          const TransferDetail(request, TransferPage([first], 'page-2')),
    );
    when(() => repository.getDetail(request.id, cursor: 'page-2')).thenAnswer(
      (_) async => const TransferDetail(request, TransferPage([second], null)),
    );
  });

  test(
    'un listado anterior a la decisión no puede volver a publicar la solicitud pendiente',
    () async {
      final cache = IncomingTransferCache(repository);
      await cache.refreshPending();
      final lateResponse = Completer<TransferPage<TransferRequest>>();
      var reads = 0;
      when(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).thenAnswer((_) {
        reads++;
        return reads == 1
            ? lateResponse.future
            : Future.value(const TransferPage([], null));
      });
      final refresh = cache.refreshPending();
      cache.removeRequest(request.id);
      lateResponse.complete(const TransferPage([request], null));
      expect((await refresh).items, isEmpty);
      expect(cache.pendingRequests!.items, isEmpty);
      expect(reads, 2);
    },
  );

  test(
    'la caché de detalles limita entradas y admite edades tipadas',
    () async {
      final cache = IncomingTransferCache(repository, maxEntries: 1);
      await cache.loadDetail(request.id);
      const other = TransferRequest(
        id: 'transfer-2',
        status: 'PENDING',
        version: 1,
        recipientName: 'Receptor',
      );
      const aged = TransferItem(
        id: 'item-3',
        animalId: 'animal-3',
        animalName: 'Luna',
        animalCode: 'AR-E019',
        animalAge: ExactTransferAnimalAge(8),
        status: 'PENDING',
      );
      when(() => repository.getDetail(other.id)).thenAnswer(
        (_) async => const TransferDetail(other, TransferPage([aged], null)),
      );
      await cache.loadDetail(other.id);
      expect(cache.peek(request.id), isNull);
      expect(
        cache.peek(other.id)!.items.single.animalAge,
        const ExactTransferAnimalAge(8),
      );
    },
  );

  test(
    'las fotos lentas no retrasan el detalle de las solicitudes siguientes',
    () async {
      final requests = [
        for (var i = 1; i <= 3; i++)
          TransferRequest(
            id: 'transfer-$i',
            status: 'PENDING',
            version: 1,
            recipientName: 'Receptor',
          ),
      ];
      when(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).thenAnswer((_) async => TransferPage(requests, null));
      for (final current in requests) {
        when(() => repository.getDetail(current.id)).thenAnswer(
          (_) async =>
              TransferDetail(current, const TransferPage([first], null)),
        );
      }
      final photos = Completer<void>();
      final started = Completer<void>();
      final cache = IncomingTransferCache(
        repository,
        preloadImage: (_) {
          if (!started.isCompleted) started.complete();
          return photos.future;
        },
      );
      await cache.refreshPending();
      final loading = cache.prefetchPending();
      await started.future;
      expect(cache.peek('transfer-3'), isNotNull);
      photos.complete();
      await loading;
    },
  );

  test(
    'el Home prepara todas las páginas y fotos y las aperturas reutilizan sus datos',
    () async {
      final photos = <String>[];
      final cache = IncomingTransferCache(
        repository,
        preloadImage: (item) async => photos.add(item.id),
      )..useAccount('owner-1');
      final home = TransferHomeNoticeCubit(repository, previewCache: cache);
      addTearDown(home.close);
      await home.refresh();
      await cache.prefetchPending();
      expect(home.state, request);
      expect(photos, ['item-1', 'item-2']);
      final inbox = TransferRequestsCubit(repository, previewCache: cache);
      addTearDown(inbox.close);
      await inbox.load(filter: 'PENDING');
      expect(inbox.state.requests, [request]);
      for (var i = 0; i < 2; i++) {
        final detail = TransferDetailCubit(
          repository,
          request.id,
          previewCache: cache,
        );
        expect(detail.state.items, [first, second]);
        expect(detail.state.loading, isFalse);
        await detail.initialize();
        await detail.close();
      }
      await home.refresh();
      await cache.prefetchPending();
      expect(photos, ['item-1', 'item-2']);
      verify(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).called(2);
      verify(() => repository.getDetail(request.id)).called(1);
      verify(
        () => repository.getDetail(request.id, cursor: 'page-2'),
      ).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test(
    'la foto de la segunda página renueva el detalle correcto y conserva la selección',
    () async {
      final cache = IncomingTransferCache(repository);
      await cache.loadDetail(request.id);
      final detail = TransferDetailCubit(
        repository,
        request.id,
        previewCache: cache,
      );
      addTearDown(detail.close);
      detail.toggleAnimal(second.animalId);
      final renewed = second.withAnimalImageUrl(
        'https://example.com/photo?Signature=new',
      );
      when(() => repository.getDetail(request.id, cursor: 'page-2')).thenAnswer(
        (_) async => TransferDetail(request, TransferPage([renewed], null)),
      );
      await detail.refreshAnimalImage(second.id, second.animalImageUrl!);
      expect(detail.state.items, [first, renewed]);
      expect(detail.state.selectedAnimalIds, {second.animalId});
      expect(cache.peek(request.id)!.items, [first, renewed]);
      verify(() => repository.getDetail(request.id)).called(1);
      verify(
        () => repository.getDetail(request.id, cursor: 'page-2'),
      ).called(2);
    },
  );

  test(
    'una versión nueva o una decisión descarta el detalle anterior',
    () async {
      final cache = IncomingTransferCache(repository);
      await cache.refreshPending();
      await cache.loadDetail(request.id);
      const next = TransferRequest(
        id: 'transfer-1',
        status: 'PENDING',
        version: 4,
        recipientName: 'Receptor',
      );
      when(
        () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
      ).thenAnswer((_) async => const TransferPage([next], null));
      await cache.refreshPending();
      expect(cache.peek(request.id), isNull);
      when(() => repository.getDetail(request.id)).thenAnswer(
        (_) async => const TransferDetail(next, TransferPage([first], null)),
      );
      await cache.loadDetail(request.id);
      cache.removeRequest(request.id);
      expect(cache.pendingRequests!.items, isEmpty);
      expect(cache.peek(request.id), isNull);
    },
  );

  test('solicitudes en páginas siguientes también se precargan', () async {
    const other = TransferRequest(
      id: 'transfer-2',
      status: 'PENDING',
      version: 1,
      recipientName: 'Receptor',
    );
    when(
      () => repository.listRequests(direction: 'INCOMING', status: 'PENDING'),
    ).thenAnswer((_) async => const TransferPage([request], 'requests-2'));
    when(
      () => repository.listRequests(
        direction: 'INCOMING',
        status: 'PENDING',
        cursor: 'requests-2',
      ),
    ).thenAnswer((_) async => const TransferPage([other], null));
    when(() => repository.getDetail(other.id)).thenAnswer(
      (_) async => const TransferDetail(other, TransferPage([], null)),
    );
    final cache = IncomingTransferCache(repository);
    await cache.refreshPending();
    await cache.prefetchPending();
    expect(cache.peek(request.id)?.items.length, 2);
    expect(cache.peek(other.id)?.request, other);
    expect(cache.pendingRequests!.nextCursor, isNull);
  });

  test(
    'abrir durante la precarga comparte la llamada y cambiar de cuenta descarta el resultado',
    () async {
      final response = Completer<TransferDetail>();
      when(
        () => repository.getDetail(request.id),
      ).thenAnswer((_) => response.future);
      final cache = IncomingTransferCache(repository)..useAccount('owner-1');
      final loading = cache.loadDetail(request.id);
      final detail = TransferDetailCubit(
        repository,
        request.id,
        previewCache: cache,
      );
      addTearDown(detail.close);
      final opening = detail.initialize();
      final expected = expectLater(loading, throwsStateError);
      cache.useAccount('owner-2');
      response.complete(
        const TransferDetail(request, TransferPage([first], null)),
      );
      await expected;
      await opening;
      expect(cache.peek(request.id), isNull);
      expect(cache.pendingRequests, isNull);
      verify(() => repository.getDetail(request.id)).called(1);
    },
  );

  test(
    'una decisión incierta conserva clave, versión y selección aunque se descarte la caché',
    () async {
      final cache = IncomingTransferCache(repository);
      await cache.refreshPending();
      await cache.loadDetail(request.id);
      final detail = TransferDetailCubit(
        repository,
        request.id,
        previewCache: cache,
      );
      addTearDown(detail.close);
      final keys = <String>[];
      const accepted = TransferRequest(
        id: 'transfer-1',
        status: 'PARTIALLY_ACCEPTED',
        version: 4,
        recipientName: 'Receptor',
      );
      when(
        () => repository.decide(
          id: request.id,
          expectedVersion: 3,
          acceptedAnimalIds: [first.animalId],
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        keys.add(invocation.namedArguments[#idempotencyKey] as String);
        if (keys.length == 1) {
          throw const ApiException(message: 'Incierto', statusCode: 503);
        }
        when(() => repository.getDetail(request.id)).thenAnswer(
          (_) async => const TransferDetail(
            accepted,
            TransferPage([first, second], null),
          ),
        );
        return accepted;
      });
      detail.toggleAnimal(first.animalId);
      await detail.decide([first.animalId]);
      expect(cache.peek(request.id), isNull);
      detail.toggleAnimal(second.animalId);
      expect(detail.state.selectedAnimalIds, {first.animalId});
      await detail.retryDecision();
      expect(keys, [keys.first, keys.first]);
      expect(cache.pendingRequests!.items, isEmpty);
      expect(detail.state.request!.status, 'PARTIALLY_ACCEPTED');
    },
  );

  test(
    'un fallo de precarga mantiene el aviso y permite cargar la solicitud al abrir',
    () async {
      var failed = true;
      when(() => repository.getDetail(request.id)).thenAnswer((_) async {
        if (failed) {
          throw const ApiException(message: 'Sin conexión', statusCode: 503);
        }
        return const TransferDetail(request, TransferPage([first], 'page-2'));
      });
      final cache = IncomingTransferCache(repository);
      final home = TransferHomeNoticeCubit(repository, previewCache: cache);
      addTearDown(home.close);
      await home.refresh();
      await cache.prefetchPending();
      expect(home.state, request);
      expect(cache.peek(request.id), isNull);
      failed = false;
      final detail = TransferDetailCubit(
        repository,
        request.id,
        previewCache: cache,
      );
      addTearDown(detail.close);
      await detail.initialize();
      expect(detail.state.items, [first, second]);
      expect(detail.state.error, isNull);
    },
  );
}
