import 'dart:typed_data';

import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:animal_record/core/services/media_file_service.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';
import 'package:animal_record/features/home/domain/usecases/upload_animal_picture_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnimalRepository extends Mock implements AnimalRepository {}

class MockMediaFileService extends Mock implements MediaFileService {}

class MockFileUploader extends Mock implements FileUploader {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockAnimalRepository repository;
  late MockMediaFileService mediaFileService;
  late MockFileUploader fileUploader;
  late UploadAnimalPictureUseCase useCase;

  const animalId = 'animal-1';
  const imagePath = 'image.jpg';
  const uploadUrl = 'https://s3.example.com/upload';
  const finalUrl = 'https://cdn.example.com/animal.jpg';
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  setUp(() {
    repository = MockAnimalRepository();
    mediaFileService = MockMediaFileService();
    fileUploader = MockFileUploader();
    useCase = UploadAnimalPictureUseCase(
      repository: repository,
      mediaFileService: mediaFileService,
      fileUploader: fileUploader,
    );
  });

  void stubCompression(Uint8List? result) {
    when(
      () => mediaFileService.compressImage(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      ),
    ).thenAnswer((_) async => result);
  }

  test('comprime, sube y confirma usando los parámetros actuales', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl(
        animalId,
        'image/jpeg',
        bytes.length,
      ),
    ).thenAnswer(
      (_) async => const Right({'uploadUrl': uploadUrl, 'finalUrl': finalUrl}),
    );
    when(
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: bytes,
        mimeType: 'image/jpeg',
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.confirmProfilePicture(animalId, finalUrl),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(animalId: animalId, imagePath: imagePath);

    expect(result, const Right<Failure, String>(finalUrl));
    verifyInOrder([
      () => mediaFileService.compressImage(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      ),
      () => repository.getProfilePictureUploadUrl(
        animalId,
        'image/jpeg',
        bytes.length,
      ),
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: bytes,
        mimeType: 'image/jpeg',
      ),
      () => repository.confirmProfilePicture(animalId, finalUrl),
    ]);
  });

  test('conserva el mensaje cuando la compresión no produce bytes', () async {
    stubCompression(null);

    final result = await useCase(animalId: animalId, imagePath: imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('No se pudo comprimir la imagen'),
      ),
    );
    verifyNever(
      () => repository.getProfilePictureUploadUrl(any(), any(), any()),
    );
  });

  test('conserva el mensaje cuando faltan URLs en la respuesta', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl(
        animalId,
        'image/jpeg',
        bytes.length,
      ),
    ).thenAnswer((_) async => const Right({}));

    final result = await useCase(animalId: animalId, imagePath: imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('Respuesta inválida del servidor'),
      ),
    );
    verifyNever(
      () => fileUploader.upload(
        uploadUrl: any(named: 'uploadUrl'),
        bytes: any(named: 'bytes'),
        mimeType: any(named: 'mimeType'),
      ),
    );
  });

  test('convierte una excepción de subida al mensaje anterior', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl(
        animalId,
        'image/jpeg',
        bytes.length,
      ),
    ).thenAnswer(
      (_) async => const Right({'uploadUrl': uploadUrl, 'finalUrl': finalUrl}),
    );
    when(
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: bytes,
        mimeType: 'image/jpeg',
      ),
    ).thenThrow(Exception('falló S3'));

    final result = await useCase(animalId: animalId, imagePath: imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('Error inesperado: Exception: falló S3'),
      ),
    );
    verifyNever(() => repository.confirmProfilePicture(any(), any()));
  });
}
