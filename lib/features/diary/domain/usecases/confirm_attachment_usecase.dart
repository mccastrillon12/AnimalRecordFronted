import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class ConfirmAttachmentUseCase {
  final DiaryRepository repository;

  ConfirmAttachmentUseCase(this.repository);

  Future<Either<Failure, DiaryEntryEntity>> call({
    required String animalId,
    required String entryId,
    required String attachmentId,
    required String finalUrl,
    required String fileName,
    required String mimeType,
    required int size,
  }) {
    return repository.confirmAttachment(animalId, entryId, {
      'attachmentId': attachmentId,
      'finalUrl': finalUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'size': size,
    });
  }
}
