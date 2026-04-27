import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/diary/domain/repositories/diary_repository.dart';

class DeleteDiaryEntryUseCase {
  final DiaryRepository repository;

  DeleteDiaryEntryUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String animalId,
    required String entryId,
  }) {
    return repository.deleteDiaryEntry(animalId, entryId);
  }
}
