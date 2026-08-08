import 'dart:typed_data';

import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:animal_record/core/services/media_file_service.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/entities/local_attachment.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';
import 'package:animal_record/features/diary/domain/usecases/upload_diary_attachment_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockMediaFileService extends Mock implements MediaFileService {}

class MockFileUploader extends Mock implements FileUploader {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<String, dynamic>{});
  });

  late MockDiaryRepository repository;
  late MockMediaFileService mediaFileService;
  late MockFileUploader fileUploader;
  late UploadDiaryAttachmentUseCase useCase;

  const animalId = 'animal-1';
  const entryId = 'entry-1';
  const uploadUrl = 'https://s3.example.com/upload';
  const finalUrl = 'https://cdn.example.com/file.jpg';
  const attachmentId = 'attachment-1';
  final compressedBytes = Uint8List.fromList([1, 2, 3]);
  final rawBytes = Uint8List.fromList([4, 5, 6, 7]);

  const image = LocalAttachment(
    path: 'photo.png',
    fileName: 'photo.png',
    mimeType: 'image/png',
    fileType: 'image',
    size: 999,
  );
  const audio = LocalAttachment(
    path: 'note.m4a',
    fileName: 'note.m4a',
    mimeType: 'audio/mp4',
    fileType: 'audio',
    size: 999,
  );
  const confirmedEntry = DiaryEntryEntity(
    id: entryId,
    animalId: animalId,
    title: 'Nota',
    content: 'Contenido',
    date: '2026-07-10',
    attachments: [],
    createdAt: '2026-07-10',
    updatedAt: '2026-07-10',
  );

  setUp(() {
    repository = MockDiaryRepository();
    mediaFileService = MockMediaFileService();
    fileUploader = MockFileUploader();
    useCase = UploadDiaryAttachmentUseCase(
      repository: repository,
      mediaFileService: mediaFileService,
      fileUploader: fileUploader,
    );
  });

  void stubUploadUrl(String mimeType, int size) {
    when(
      () =>
          repository.getAttachmentUploadUrl(animalId, entryId, mimeType, size),
    ).thenAnswer(
      (_) async => const Right({
        'uploadUrl': uploadUrl,
        'finalUrl': finalUrl,
        'attachmentId': attachmentId,
      }),
    );
  }

  void stubUploader(Uint8List bytes, String mimeType) {
    when(
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      ),
    ).thenAnswer((_) async {});
  }

  void stubConfirmation() {
    when(
      () => repository.confirmAttachment(animalId, entryId, any()),
    ).thenAnswer((_) async => const Right(confirmedEntry));
  }

  test('comprime imágenes y confirma con el tamaño real', () async {
    when(
      () => mediaFileService.compressImage(
        image.path,
        minWidth: 1920,
        minHeight: 1080,
        quality: 85,
      ),
    ).thenAnswer((_) async => compressedBytes);
    stubUploadUrl('image/jpeg', compressedBytes.length);
    stubUploader(compressedBytes, 'image/jpeg');
    stubConfirmation();

    final result = await useCase(
      animalId: animalId,
      entryId: entryId,
      attachment: image,
    );

    expect(result, const Right<Failure, void>(null));
    verifyInOrder([
      () => mediaFileService.compressImage(
        image.path,
        minWidth: 1920,
        minHeight: 1080,
        quality: 85,
      ),
      () => repository.getAttachmentUploadUrl(
        animalId,
        entryId,
        'image/jpeg',
        compressedBytes.length,
      ),
      () => fileUploader.upload(
        uploadUrl: uploadUrl,
        bytes: compressedBytes,
        mimeType: 'image/jpeg',
      ),
    ]);
    final confirmation =
        verify(
              () =>
                  repository.confirmAttachment(animalId, entryId, captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(confirmation, {
      'attachmentId': attachmentId,
      'finalUrl': finalUrl,
      'fileName': image.fileName,
      'mimeType': 'image/jpeg',
      'size': compressedBytes.length,
    });
  });

  test('usa los bytes originales si la compresión retorna null', () async {
    when(
      () => mediaFileService.compressImage(
        image.path,
        minWidth: 1920,
        minHeight: 1080,
        quality: 85,
      ),
    ).thenAnswer((_) async => null);
    when(
      () => mediaFileService.readBytes(image.path),
    ).thenAnswer((_) async => rawBytes);
    stubUploadUrl('image/jpeg', rawBytes.length);
    stubUploader(rawBytes, 'image/jpeg');
    stubConfirmation();

    final result = await useCase(
      animalId: animalId,
      entryId: entryId,
      attachment: image,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => mediaFileService.readBytes(image.path)).called(1);
  });

  test('lee audio sin intentar comprimirlo y conserva su MIME', () async {
    when(
      () => mediaFileService.readBytes(audio.path),
    ).thenAnswer((_) async => rawBytes);
    stubUploadUrl(audio.mimeType, rawBytes.length);
    stubUploader(rawBytes, audio.mimeType);
    when(
      () => repository.confirmAttachment(animalId, entryId, any()),
    ).thenAnswer((_) async => const Right(confirmedEntry));

    final result = await useCase(
      animalId: animalId,
      entryId: entryId,
      attachment: audio,
    );

    expect(result, const Right<Failure, void>(null));
    verifyNever(
      () => mediaFileService.compressImage(
        any(),
        minWidth: any(named: 'minWidth'),
        minHeight: any(named: 'minHeight'),
        quality: any(named: 'quality'),
      ),
    );
  });

  test('conserva el comportamiento best-effort ante fallo de URL', () async {
    when(
      () => mediaFileService.readBytes(audio.path),
    ).thenAnswer((_) async => rawBytes);
    when(
      () => repository.getAttachmentUploadUrl(
        animalId,
        entryId,
        audio.mimeType,
        rawBytes.length,
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('No disponible')));

    final result = await useCase(
      animalId: animalId,
      entryId: entryId,
      attachment: audio,
    );

    expect(result, const Right<Failure, void>(null));
  });

  test(
    'reporta excepciones técnicas para que el Cubit detenga el flujo',
    () async {
      when(
        () => mediaFileService.readBytes(audio.path),
      ).thenAnswer((_) async => rawBytes);
      stubUploadUrl(audio.mimeType, rawBytes.length);
      when(
        () => fileUploader.upload(
          uploadUrl: uploadUrl,
          bytes: rawBytes,
          mimeType: audio.mimeType,
        ),
      ).thenThrow(Exception('falló S3'));

      final result = await useCase(
        animalId: animalId,
        entryId: entryId,
        attachment: audio,
      );

      expect(
        result,
        const Left<Failure, void>(
          ServerFailure('Error inesperado: Exception: falló S3'),
        ),
      );
    },
  );
}
