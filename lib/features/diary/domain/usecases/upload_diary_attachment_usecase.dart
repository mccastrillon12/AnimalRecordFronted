import 'dart:typed_data';

import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:animal_record/core/services/media_file_service.dart';
import 'package:animal_record/features/diary/domain/entities/local_attachment.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';
import 'package:dartz/dartz.dart';

class UploadDiaryAttachmentUseCase {
  final DiaryRepository repository;
  final MediaFileService mediaFileService;
  final FileUploader fileUploader;

  const UploadDiaryAttachmentUseCase({
    required this.repository,
    required this.mediaFileService,
    required this.fileUploader,
  });

  Future<Either<Failure, void>> call({
    required String animalId,
    required String entryId,
    required LocalAttachment attachment,
  }) async {
    try {
      final bytes = await _prepareBytes(attachment);
      final mimeType = attachment.fileType == 'image'
          ? 'image/jpeg'
          : attachment.mimeType;

      final urlResult = await repository.getAttachmentUploadUrl(
        animalId,
        entryId,
        mimeType,
        bytes.length,
      );

      return await urlResult.fold<Future<Either<Failure, void>>>(
        (_) async => const Right(null),
        (urlData) async {
          final uploadUrl = urlData['uploadUrl'] as String?;
          final finalUrl = urlData['finalUrl'] as String?;
          final attachmentId = urlData['attachmentId'] as String?;

          if (uploadUrl == null || finalUrl == null || attachmentId == null) {
            return const Right(null);
          }

          await fileUploader.upload(
            uploadUrl: uploadUrl,
            bytes: bytes,
            mimeType: mimeType,
          );

          await repository.confirmAttachment(animalId, entryId, {
            'attachmentId': attachmentId,
            'finalUrl': finalUrl,
            'fileName': attachment.fileName,
            'mimeType': mimeType,
            'size': bytes.length,
          });

          return const Right(null);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  Future<Uint8List> _prepareBytes(LocalAttachment attachment) async {
    if (attachment.fileType != 'image') {
      return mediaFileService.readBytes(attachment.path);
    }

    final compressed = await mediaFileService.compressImage(
      attachment.path,
      minWidth: 1920,
      minHeight: 1080,
      quality: 85,
    );

    if (compressed != null) return compressed;
    return mediaFileService.readBytes(attachment.path);
  }
}
