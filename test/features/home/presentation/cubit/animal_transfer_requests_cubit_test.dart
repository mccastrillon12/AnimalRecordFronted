import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_by_id_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TransferRepository extends Mock implements AnimalTransferRepository {}

class _GetAnimalById extends Mock implements GetAnimalByIdUseCase {}

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

  test(
    'consulta la foto del animal cuando no viene en la transferencia',
    () async {
      final getAnimalById = _GetAnimalById();
      final animalResult = Completer<Either<Failure, AnimalEntity>>();
      final photoCubit = TransferDetailCubit(
        repository,
        request.id,
        getAnimalByIdUseCase: getAnimalById,
      );
      addTearDown(photoCubit.close);
      when(() => repository.getDetail(request.id)).thenAnswer(
        (_) async => const TransferDetail(request, TransferPage([item], null)),
      );
      when(
        () => getAnimalById(item.animalId),
      ).thenAnswer((_) => animalResult.future);

      await photoCubit.refresh();
      expect(photoCubit.state.items.single.animalImageUrl, isNull);
      animalResult.complete(
        const Right(
          AnimalEntity(
            id: 'animal-1',
            name: 'Spot',
            species: 'CANINE',
            breed: 'Labrador',
            sex: 'MALE',
            reproductiveStatus: 'INTACT',
            hasChip: false,
            isAssociationMember: false,
            temperament: [],
            diagnosis: [],
            ownerId: 'owner-1',
            profilePictureUrl: 'https://example.com/spot.jpg',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        photoCubit.state.items.single.animalImageUrl,
        'https://example.com/spot.jpg',
      );
      await photoCubit.refresh();
      expect(
        photoCubit.state.items.single.animalImageUrl,
        'https://example.com/spot.jpg',
      );
      verify(() => getAnimalById(item.animalId)).called(1);
    },
  );

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
