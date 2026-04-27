import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class CreateDiaryEntryUseCase {
  final DiaryRepository repository;

  CreateDiaryEntryUseCase(this.repository);

  Future<Either<Failure, DiaryEntryEntity>> call({
    required String animalId,
    required String title,
    required String content,
    required String date,
  }) {
    return repository.createDiaryEntry(animalId, {
      'title': title,
      'content': content,
      'date': date,
    });
  }
}
