import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class GetAnimalPictureUploadUrlUseCase {
  final AnimalRepository repository;

  GetAnimalPictureUploadUrlUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String animalId,
    required String mimeType,
    required int fileSize,
  }) {
    return repository.getProfilePictureUploadUrl(animalId, mimeType, fileSize);
  }
}
