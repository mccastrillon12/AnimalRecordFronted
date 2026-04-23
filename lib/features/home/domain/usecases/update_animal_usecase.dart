import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class UpdateAnimalUseCase {
  final AnimalRepository repository;

  UpdateAnimalUseCase(this.repository);

  Future<Either<Failure, AnimalEntity>> call(UpdateAnimalParams params) async {
    return await repository.updateAnimal(params);
  }
}
