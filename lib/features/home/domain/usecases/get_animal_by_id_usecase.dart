import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class GetAnimalByIdUseCase {
  final AnimalRepository repository;

  GetAnimalByIdUseCase(this.repository);

  Future<Either<Failure, AnimalEntity>> call(String id) async {
    return await repository.getAnimalById(id);
  }
}
