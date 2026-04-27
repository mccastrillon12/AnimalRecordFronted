import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class GetAttachmentUploadUrlUseCase {
  final DiaryRepository repository;

  GetAttachmentUploadUrlUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String animalId,
    required String entryId,
    required String mimeType,
    required int fileSize,
  }) {
    return repository.getAttachmentUploadUrl(
      animalId,
      entryId,
      mimeType,
      fileSize,
    );
  }
}
