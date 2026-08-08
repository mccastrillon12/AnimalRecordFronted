import 'dart:typed_data';

import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:animal_record/core/services/media_file_service.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:animal_record/features/auth/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMediaFileService extends Mock implements MediaFileService {}

class MockFileUploader extends Mock implements FileUploader {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockAuthRepository repository;
  late MockMediaFileService mediaFileService;
  late MockFileUploader fileUploader;
  late UploadProfilePictureUseCase useCase;

  const imagePath = 'profile.jpg';
  const uploadUrl = 'https://s3.example.com/upload';
  const finalUrl = 'https://cdn.example.com/profile.jpg';
  final bytes = Uint8List.fromList([1, 2, 3]);

  const confirmedUser = UserEntity(
    id: 'user-1',
    name: 'Ana',
    identificationType: 'CC',
    identificationNumber: '123',
    country: 'Colombia',
    countryId: 'CO',
    departmentId: '11',
    city: 'Bogotá',
    cityId: '11001',
    email: 'ana@example.com',
    cellPhone: '3000000000',
    animalTypes: [],
    services: [],
    isHomeDelivery: false,
    roles: ['OWNER'],
    authMethod: 'EMAIL',
    isVerified: true,
  );

  setUp(() {
    repository = MockAuthRepository();
    mediaFileService = MockMediaFileService();
    fileUploader = MockFileUploader();
    useCase = UploadProfilePictureUseCase(
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

  test('comprime, sube y confirma la foto con el contrato actual', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl('image/jpeg', bytes.length),
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
      () => repository.confirmProfilePicture(finalUrl),
    ).thenAnswer((_) async => const Right(confirmedUser));

    final result = await useCase(imagePath);

    expect(result, const Right<Failure, String>(finalUrl));
    verifyInOrder([
      () => mediaFileService.compressImage(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      ),
      () => repository.getProfilePictureUploadUrl('image/jpeg', bytes.length),
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: bytes,
        mimeType: 'image/jpeg',
      ),
      () => repository.confirmProfilePicture(finalUrl),
    ]);
  });

  test('detiene el flujo cuando no puede comprimir', () async {
    stubCompression(null);

    final result = await useCase(imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('No se pudo comprimir la imagen'),
      ),
    );
    verifyNever(() => repository.getProfilePictureUploadUrl(any(), any()));
  });

  test('rechaza una respuesta sin URLs conservando el mensaje', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl('image/jpeg', bytes.length),
    ).thenAnswer((_) async => const Right({}));

    final result = await useCase(imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('Respuesta inválida del servidor'),
      ),
    );
  });

  test('convierte excepciones técnicas al mensaje anterior', () async {
    stubCompression(bytes);
    when(
      () => repository.getProfilePictureUploadUrl('image/jpeg', bytes.length),
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

    final result = await useCase(imagePath);

    expect(
      result,
      const Left<Failure, String>(
        ServerFailure('Error inesperado: Exception: falló S3'),
      ),
    );
    verifyNever(() => repository.confirmProfilePicture(any()));
  });
}
