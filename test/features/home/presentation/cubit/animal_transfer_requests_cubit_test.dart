import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TransferRepository extends Mock implements AnimalTransferRepository {}

void main() {
  const request = TransferRequest(
    id: 'transfer-1',
    status: 'PENDING',
    version: 3,
    recipientName: 'Receptor',
    animalCount: 1,
  );
  const item = TransferItem(
    id: 'item-1',
    animalId: 'animal-1',
    animalName: 'Spot',
    animalCode: 'AR-C041',
    status: 'PENDING',
  );

  late _TransferRepository repository;
  late TransferDetailCubit cubit;

  setUp(() {
    repository = _TransferRepository();
    cubit = TransferDetailCubit(repository, request.id);
  });
  tearDown(() => cubit.close());

  test('mantiene la foto ausente sin pedir la ficha vigente', () async {
    when(() => repository.getDetail(request.id)).thenAnswer(
      (_) async => const TransferDetail(request, TransferPage([item], null)),
    );
    await cubit.refresh();
    expect(cubit.state.items.single.animalImageUrl, isNull);
    verify(() => repository.getDetail(request.id)).called(1);
    verifyNoMoreInteractions(repository);
  });

  test(
    'renueva la foto en la segunda página sin perder selección ni páginas',
    () async {
      const photo = TransferItem(
        id: 'item-2',
        animalId: 'animal-2',
        animalName: 'Luna',
        animalCode: 'AR-C002',
        status: 'PENDING',
        animalImageUrl: 'https://example.com/photo?signature=old&key=a%2Bb',
      );
      const renewed = TransferItem(
        id: 'item-2',
        animalId: 'animal-2',
        animalName: 'Luna',
        animalCode: 'AR-C002',
        status: 'PENDING',
        animalImageUrl: 'https://example.com/photo?signature=new&key=a%2Bb',
      );
      when(() => repository.getDetail(request.id)).thenAnswer(
        (_) async =>
            const TransferDetail(request, TransferPage([item], 'next')),
      );
      var page = const TransferDetail(request, TransferPage([photo], null));
      when(
        () => repository.getDetail(request.id, cursor: 'next'),
      ).thenAnswer((_) async => page);
      await cubit.refresh();
      await cubit.loadMore();
      cubit.toggleAnimal(photo.animalId);
      page = const TransferDetail(request, TransferPage([renewed], null));
      await cubit.refreshAnimalImage(photo.id, photo.animalImageUrl!);
      expect(cubit.state.items, [item, renewed]);
      expect(cubit.state.selectedAnimalIds, {photo.animalId});
      expect(cubit.state.cursor, isNull);
      await cubit.refreshAnimalImage(photo.id, renewed.animalImageUrl!);
      verify(() => repository.getDetail(request.id)).called(1);
      verify(() => repository.getDetail(request.id, cursor: 'next')).called(2);
      verifyNoMoreInteractions(repository);
    },
  );

  test('el reintento conserva clave, versión y selección originales', () async {
    final keys = <String>[];
    when(() => repository.getDetail(request.id)).thenAnswer(
      (_) async => const TransferDetail(request, TransferPage([item], null)),
    );
    when(
      () => repository.decide(
        id: request.id,
        expectedVersion: request.version,
        acceptedAnimalIds: [item.animalId],
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((invocation) async {
      keys.add(invocation.namedArguments[#idempotencyKey] as String);
      if (keys.length == 1) {
        throw const ApiException(message: 'Incierto', statusCode: 503);
      }
      return request;
    });
    await cubit.refresh();
    cubit.toggleAnimal(item.animalId);
    await cubit.decide([item.animalId]);
    cubit.toggleAnimal(item.animalId);
    cubit.toggleAllAnimals();
    expect(cubit.state.selectedAnimalIds, {item.animalId});
    await cubit.retryDecision();
    expect(keys, [keys.first, keys.first]);
    verify(
      () => repository.decide(
        id: request.id,
        expectedVersion: request.version,
        acceptedAnimalIds: [item.animalId],
        idempotencyKey: keys.first,
      ),
    ).called(2);
  });

  test('envía la decisión para el único animal pendiente', () async {
    var detail = const TransferDetail(request, TransferPage([item], null));
    const acceptedRequest = TransferRequest(
      id: 'transfer-1',
      status: 'ACCEPTED',
      version: 4,
      recipientName: 'Receptor',
      animalCount: 1,
    );
    when(
      () => repository.getDetail(request.id),
    ).thenAnswer((_) async => detail);
    when(
      () => repository.decide(
        id: request.id,
        expectedVersion: request.version,
        acceptedAnimalIds: [item.animalId],
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {
      detail = const TransferDetail(
        acceptedRequest,
        TransferPage([item], null),
      );
      return acceptedRequest;
    });

    await cubit.refresh();
    await cubit.decide([cubit.state.singlePendingAnimalId!]);

    expect(cubit.state.request?.status, 'ACCEPTED');
    verify(
      () => repository.decide(
        id: request.id,
        expectedVersion: request.version,
        acceptedAnimalIds: [item.animalId],
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
  });

  test('carga todas las páginas y permite seleccionar los animales', () async {
    const second = TransferItem(
      id: 'item-2',
      animalId: 'animal-2',
      animalName: 'Luna',
      animalCode: 'AR-C042',
      status: 'PENDING',
    );
    when(() => repository.getDetail(request.id)).thenAnswer(
      (_) async => const TransferDetail(request, TransferPage([item], 'next')),
    );
    when(() => repository.getDetail(request.id, cursor: 'next')).thenAnswer(
      (_) async => const TransferDetail(request, TransferPage([second], null)),
    );

    await cubit.refresh();
    expect(await cubit.loadAllAnimals(), isTrue);
    expect(cubit.state.items, hasLength(2));
    cubit.toggleAllAnimals();
    expect(cubit.state.selectedAnimalIds, {item.animalId, second.animalId});
    cubit.toggleAnimal(item.animalId);
    expect(cubit.state.selectedAnimalIds, {second.animalId});
  });

  test(
    'informa el envío y conserva el reintento si la respuesta es incierta',
    () async {
      final decision = Completer<TransferRequest>();
      when(() => repository.getDetail(request.id)).thenAnswer(
        (_) async => const TransferDetail(request, TransferPage([item], null)),
      );
      when(
        () => repository.decide(
          id: request.id,
          expectedVersion: request.version,
          acceptedAnimalIds: const [],
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) => decision.future);

      await cubit.refresh();
      final submitting = cubit.decide(const []);
      expect(cubit.state.submittingDecision, isTrue);

      decision.completeError(
        const ApiException(message: 'Ocupado', statusCode: 503),
      );
      await submitting;

      expect(cubit.state.submittingDecision, isFalse);
      expect(cubit.state.error, contains('Resultado incierto'));
      expect(cubit.state.canRetryDecision, isTrue);
    },
  );
}
