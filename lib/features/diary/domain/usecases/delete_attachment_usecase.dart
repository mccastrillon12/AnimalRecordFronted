import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class DeleteAttachmentUseCase {
  final DiaryRepository repository;

  DeleteAttachmentUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String animalId,
    required String entryId,
    required String attachmentId,
  }) {
    return repository.deleteAttachment(animalId, entryId, attachmentId);
  }
}
