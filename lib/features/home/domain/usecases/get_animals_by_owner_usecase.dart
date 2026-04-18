import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class GetAnimalsByOwnerUseCase {
  final AnimalRepository repository;

  GetAnimalsByOwnerUseCase(this.repository);

  Future<Either<Failure, List<AnimalEntity>>> call(String ownerId) async {
    return await repository.getAnimalsByOwner(ownerId);
  }
}
