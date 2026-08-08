import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
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

void main() {
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
