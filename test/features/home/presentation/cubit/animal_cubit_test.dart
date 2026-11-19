import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'dart:convert';
import 'dart:io';
import 'package:animal_record/features/home/data/services/historical_animal_photo_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/data/services/animal_history_cache.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/usecases/confirm_animal_picture_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/create_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_by_id_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/get_animals_by_owner_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/search_animals_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/update_animal_usecase.dart';
import 'package:animal_record/features/home/domain/usecases/upload_animal_picture_usecase.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateAnimalUseCase extends Mock implements CreateAnimalUseCase {}

class MockGetAnimalsByOwnerUseCase extends Mock
    implements GetAnimalsByOwnerUseCase {}

class MockGetAnimalByIdUseCase extends Mock implements GetAnimalByIdUseCase {}

class MockUpdateAnimalUseCase extends Mock implements UpdateAnimalUseCase {}

class MockConfirmAnimalPictureUseCase extends Mock
    implements ConfirmAnimalPictureUseCase {}

class MockSearchAnimalsUseCase extends Mock implements SearchAnimalsUseCase {}

class MockUploadAnimalPictureUseCase extends Mock
    implements UploadAnimalPictureUseCase {}

class _HistoryRepository extends Mock implements AnimalTransferRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockGetAnimalsByOwnerUseCase getAnimalsByOwnerUseCase;
  late MockUploadAnimalPictureUseCase uploadAnimalPictureUseCase;
  late AnimalCubit cubit;

  const ownerId = 'owner-1';
  const animalId = 'animal-1';
  const imagePath = 'animal.jpg';
  const finalUrl = 'https://cdn.example.com/animal.jpg';

  const originalAnimal = AnimalEntity(
    id: animalId,
    name: 'Luna',
    species: 'CAT',
    breed: 'Criollo',
    sex: 'FEMALE',
    reproductiveStatus: 'STERILIZED',
    hasChip: false,
    isAssociationMember: false,
    temperament: [],
    diagnosis: [],
    ownerId: ownerId,
  );

  const updatedAnimal = AnimalEntity(
    id: animalId,
    name: 'Luna',
    species: 'CAT',
    breed: 'Criollo',
    sex: 'FEMALE',
    reproductiveStatus: 'STERILIZED',
    hasChip: false,
    isAssociationMember: false,
    temperament: [],
    diagnosis: [],
    ownerId: ownerId,
    profilePictureUrl: finalUrl,
  );

  setUp(() {
    getAnimalsByOwnerUseCase = MockGetAnimalsByOwnerUseCase();
    uploadAnimalPictureUseCase = MockUploadAnimalPictureUseCase();
    cubit = AnimalCubit(
      createAnimalUseCase: MockCreateAnimalUseCase(),
      getAnimalsByOwnerUseCase: getAnimalsByOwnerUseCase,
      getAnimalByIdUseCase: MockGetAnimalByIdUseCase(),
      updateAnimalUseCase: MockUpdateAnimalUseCase(),
      confirmAnimalPictureUseCase: MockConfirmAnimalPictureUseCase(),
      searchAnimalsUseCase: MockSearchAnimalsUseCase(),
      uploadAnimalPictureUseCase: uploadAnimalPictureUseCase,
    );
  });

  tearDown(() => cubit.close());

  test(
    'la lista prepara la información histórica y la mantiene al actualizar sin afectar una devolución',
    () async {
      final repository = _HistoryRepository();
      final cache = AnimalHistoryCache(repository);
      final directory = await Directory.systemTemp.createTemp(
        'animal-list-photo-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photos = HistoricalAnimalPhotoCache(
        readAccountId: () async => ownerId,
        cacheDirectory: () async => directory,
      );
      final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      when(
        () => repository.downloadHistoricalFile(
          periodId: 'period-1',
          publicationHash: 'hash-1',
          entryId: 'animal-entry',
          fileId: 'photo-1',
        ),
      ).thenAnswer((_) async => image);
      final cachedCubit = AnimalCubit(
        createAnimalUseCase: cubit.createAnimalUseCase,
        getAnimalsByOwnerUseCase: getAnimalsByOwnerUseCase,
        getAnimalByIdUseCase: cubit.getAnimalByIdUseCase,
        updateAnimalUseCase: cubit.updateAnimalUseCase,
        confirmAnimalPictureUseCase: cubit.confirmAnimalPictureUseCase,
        searchAnimalsUseCase: cubit.searchAnimalsUseCase,
        uploadAnimalPictureUseCase: uploadAnimalPictureUseCase,
        historicalAnimalLoader: LoadHistoricalAnimalUseCase(
          cache,
          photos: photos,
          downloadFile: DownloadHistoricalFileUseCase(repository),
        ),
      );
      addTearDown(cachedCubit.close);
      final card = AnimalDataModel.fromJson({
        'id': animalId,
        'name': 'Luna',
        'species': 'CAT',
        'sex': 'FEMALE',
        'transferStatus': 'TRANSFERRED',
        'readOnly': true,
        'ownershipHistory': {
          'periodId': 'period-1',
          'publicationHash': 'hash-1',
        },
      });
      when(
        () => getAnimalsByOwnerUseCase(ownerId),
      ).thenAnswer((_) async => Right([card]));
      when(() => repository.getHistory('period-1', 'hash-1')).thenAnswer(
        (_) async => const TransferPage([
          HistoricalEntry(
            entryId: 'animal-entry',
            kind: 'ANIMAL',
            data: {
              'id': animalId,
              'name': 'Luna guardada',
              'species': 'CAT',
              'sex': 'FEMALE',
              'weight': 4.5,
            },
            media: [HistoricalFile('photo-1', 'profilePictureUrl')],
          ),
        ], null),
      );
      final ready = cachedCubit.stream.firstWhere(
        (state) => state is AnimalsLoaded && state.animals.single.weight == 4.5,
      );
      await cachedCubit.loadAnimals(ownerId);
      await ready;
      expect(
        photos.peek(cachedCubit.animals.single.ownershipHistory!.photo!),
        image,
      );
      expect(cachedCubit.animals.single.weight, 4.5);
      await cachedCubit.loadAnimals(ownerId, forceRefresh: true);
      expect(cachedCubit.animals.single.ownershipHistory?.isLoaded, isFalse);
      expect(
        cache.peek(cachedCubit.animals.single.ownershipHistory!)?.isLoaded,
        isTrue,
      );
      verify(() => repository.getHistory('period-1', 'hash-1')).called(1);
      verify(
        () => repository.downloadHistoricalFile(
          periodId: 'period-1',
          publicationHash: 'hash-1',
          entryId: 'animal-entry',
          fileId: 'photo-1',
        ),
      ).called(1);
      when(
        () => getAnimalsByOwnerUseCase(ownerId),
      ).thenAnswer((_) async => const Right([updatedAnimal]));
      await cachedCubit.loadAnimals(ownerId, forceRefresh: true);
      expect(cachedCubit.animals, [updatedAnimal]);
      expect(cachedCubit.animals.single.canWrite, isTrue);
      cachedCubit.reset();
      expect(cache.peek(card.ownershipHistory!), isNull);
    },
  );

  test(
    'el histórico bloquea cambios y la devolución recupera una sola ficha editable',
    () async {
      final historical = AnimalDataModel.fromJson({
        'id': animalId,
        'name': 'Luna',
        'species': 'CAT',
        'sex': 'FEMALE',
        'transferStatus': 'TRANSFERRED',
        'readOnly': true,
        'isActive': true,
        'ownershipHistory': {
          'periodId': 'period-1',
          'publicationHash': 'published',
        },
      });
      when(
        () => getAnimalsByOwnerUseCase(ownerId),
      ).thenAnswer((_) async => Right([historical]));
      await cubit.loadAnimals(ownerId);
      await cubit.loadAnimalDetails(animalId);
      await cubit.updateAnimal(
        const UpdateAnimalParams(
          id: animalId,
          name: 'Cambio',
          species: 'CAT',
          breed: '',
          sex: 'FEMALE',
          reproductiveStatus: '',
          hasChip: false,
          isAssociationMember: false,
          temperament: [],
          diagnosis: [],
          ownerId: ownerId,
        ),
      );
      await cubit.updateProfilePicture(animalId, imagePath);
      await cubit.deleteProfilePicture(animalId);
      verifyZeroInteractions(cubit.getAnimalByIdUseCase as Mock);
      verifyZeroInteractions(cubit.updateAnimalUseCase as Mock);
      verifyZeroInteractions(uploadAnimalPictureUseCase);
      verifyZeroInteractions(cubit.confirmAnimalPictureUseCase as Mock);
      expect(cubit.animals.single.isActive, isTrue);
      expect(cubit.animals.single.canWrite, isFalse);

      final returned = AnimalDataModel.fromJson({
        'id': animalId,
        'name': 'Luna Actualizada',
        'species': 'CAT',
        'sex': 'FEMALE',
        'ownerId': ownerId,
        'profilePictureUrl': finalUrl,
        'weight': 4.5,
      });
      when(
        () => getAnimalsByOwnerUseCase(ownerId),
      ).thenAnswer((_) async => Right([historical, returned, returned]));
      await cubit.loadAnimals(ownerId, forceRefresh: true);
      expect(cubit.animals, [returned]);
      expect(cubit.animals.single.canWrite, isTrue);
      expect(cubit.animals.single.name, 'Luna Actualizada');
      expect(cubit.animals.single.weight, 4.5);
      when(
        () => uploadAnimalPictureUseCase(
          animalId: animalId,
          imagePath: imagePath,
        ),
      ).thenAnswer((_) async => const Right(finalUrl));
      await cubit.updateProfilePicture(animalId, imagePath);
      expect(cubit.state, isA<AnimalPictureUploaded>());
      verify(
        () => uploadAnimalPictureUseCase(
          animalId: animalId,
          imagePath: imagePath,
        ),
      ).called(1);
    },
  );

  test('recarga la lista del mismo dueño tras recibir un animal', () async {
    when(
      () => getAnimalsByOwnerUseCase(ownerId),
    ).thenAnswer((_) async => const Right([]));
    await cubit.loadAnimals(ownerId);

    when(
      () => getAnimalsByOwnerUseCase(ownerId),
    ).thenAnswer((_) async => const Right([originalAnimal]));
    await cubit.loadAnimals(ownerId, forceRefresh: true);
    await cubit.loadAnimals(ownerId);

    expect(cubit.state, const AnimalsLoaded([originalAnimal]));
    expect(cubit.animals, [originalAnimal]);
    verify(() => getAnimalsByOwnerUseCase(ownerId)).called(2);
  });

  test('mantiene los estados de carga y éxito al subir una imagen', () async {
    var loadCount = 0;
    when(() => getAnimalsByOwnerUseCase(ownerId)).thenAnswer((_) async {
      loadCount++;
      return Right(loadCount == 1 ? [originalAnimal] : [updatedAnimal]);
    });
    when(
      () =>
          uploadAnimalPictureUseCase(animalId: animalId, imagePath: imagePath),
    ).thenAnswer((_) async => const Right(finalUrl));

    await cubit.loadAnimals(ownerId);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AnimalPictureUploading(
          existingAnimals: [originalAnimal],
          animalId: animalId,
        ),
        const AnimalPictureUploaded(updatedAnimal, allAnimals: [updatedAnimal]),
      ]),
    );

    await cubit.updateProfilePicture(animalId, imagePath);
    await expectation;

    verify(
      () =>
          uploadAnimalPictureUseCase(animalId: animalId, imagePath: imagePath),
    ).called(1);
  });

  test('mantiene la lista y el mensaje cuando el caso de uso falla', () async {
    when(
      () => getAnimalsByOwnerUseCase(ownerId),
    ).thenAnswer((_) async => const Right([originalAnimal]));
    when(
      () =>
          uploadAnimalPictureUseCase(animalId: animalId, imagePath: imagePath),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('No se pudo subir la imagen')),
    );

    await cubit.loadAnimals(ownerId);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const AnimalPictureUploading(
          existingAnimals: [originalAnimal],
          animalId: animalId,
        ),
        const AnimalError(
          'No se pudo subir la imagen',
          existingAnimals: [originalAnimal],
        ),
      ]),
    );

    await cubit.updateProfilePicture(animalId, imagePath);
    await expectation;
  });
}
