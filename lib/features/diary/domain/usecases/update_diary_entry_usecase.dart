import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class UpdateDiaryEntryUseCase {
  final DiaryRepository repository;

  UpdateDiaryEntryUseCase(this.repository);

  Future<Either<Failure, DiaryEntryEntity>> call({
    required String animalId,
    required String entryId,
    required String title,
    required String content,
  }) {
    return repository.updateDiaryEntry(animalId, entryId, {
      'title': title,
      'content': content,
    });
  }
}
