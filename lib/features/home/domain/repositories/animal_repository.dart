import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';

abstract class AnimalRepository {
  Future<Either<Failure, AnimalEntity>> createAnimal(CreateAnimalParams params);
  Future<Either<Failure, List<AnimalEntity>>> getAnimalsByOwner(String ownerId);
}
