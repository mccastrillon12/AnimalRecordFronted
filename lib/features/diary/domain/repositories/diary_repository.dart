import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';

abstract class DiaryRepository {
  Future<Either<Failure, List<DiaryEntryEntity>>> getDiaryEntries(String animalId);
  Future<Either<Failure, DiaryEntryEntity>> createDiaryEntry(
    String animalId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, DiaryEntryEntity>> updateDiaryEntry(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> deleteDiaryEntry(
    String animalId,
    String entryId,
  );
  Future<Either<Failure, Map<String, dynamic>>> getAttachmentUploadUrl(
    String animalId,
    String entryId,
    String mimeType,
    int fileSize,
  );
  Future<Either<Failure, DiaryEntryEntity>> confirmAttachment(
    String animalId,
    String entryId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> deleteAttachment(
    String animalId,
    String entryId,
    String attachmentId,
  );
}
