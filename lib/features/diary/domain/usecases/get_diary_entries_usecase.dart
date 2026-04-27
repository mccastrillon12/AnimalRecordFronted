import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class GetDiaryEntriesUseCase {
  final DiaryRepository repository;

  GetDiaryEntriesUseCase(this.repository);

  Future<Either<Failure, List<DiaryEntryEntity>>> call(String animalId) {
    return repository.getDiaryEntries(animalId);
  }
}
