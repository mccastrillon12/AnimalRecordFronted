import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class ConfirmAnimalPictureUseCase {
  final AnimalRepository repository;

  ConfirmAnimalPictureUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String animalId,
    required String finalUrl,
  }) {
    return repository.confirmProfilePicture(animalId, finalUrl);
  }
}
