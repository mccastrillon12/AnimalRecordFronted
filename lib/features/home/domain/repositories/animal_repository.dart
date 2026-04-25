import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';

abstract class AnimalRepository {
  Future<Either<Failure, AnimalEntity>> createAnimal(CreateAnimalParams params);
  Future<Either<Failure, AnimalEntity>> updateAnimal(UpdateAnimalParams params);
  Future<Either<Failure, AnimalEntity>> getAnimalById(String id);
  Future<Either<Failure, List<AnimalEntity>>> getAnimalsByOwner(String ownerId);
  Future<Either<Failure, Map<String, dynamic>>> getProfilePictureUploadUrl(
    String animalId,
    String mimeType,
    int fileSize,
  );
  Future<Either<Failure, void>> confirmProfilePicture(
    String animalId,
    String finalUrl,
  );
}
