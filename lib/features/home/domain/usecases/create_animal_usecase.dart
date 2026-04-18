import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class CreateAnimalUseCase {
  final AnimalRepository repository;

  CreateAnimalUseCase(this.repository);

  Future<Either<Failure, AnimalEntity>> call(CreateAnimalParams params) async {
    return await repository.createAnimal(params);
  }
}
