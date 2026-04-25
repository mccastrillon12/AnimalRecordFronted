import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';
import 'package:animal_record/features/home/data/datasources/animal_remote_datasource.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  final AnimalRemoteDataSource remoteDataSource;

  AnimalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AnimalEntity>> createAnimal(
    CreateAnimalParams params,
  ) async {
    try {
      final result = await remoteDataSource.createAnimal(params.toJson());
      return Right(result);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, AnimalEntity>> updateAnimal(
    UpdateAnimalParams params,
  ) async {
    try {
      final result = await remoteDataSource.updateAnimal(
        params.id,
        params.toJson(),
      );
      return Right(result);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, AnimalEntity>> getAnimalById(String id) async {
    try {
      final result = await remoteDataSource.getAnimalById(id);
      return Right(result);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, List<AnimalEntity>>> getAnimalsByOwner(
    String ownerId,
  ) async {
    try {
      final result = await remoteDataSource.getAnimalsByOwner(ownerId);
      return Right(result);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProfilePictureUploadUrl(
    String animalId,
    String mimeType,
    int fileSize,
  ) async {
    try {
      final data = await remoteDataSource.getProfilePictureUploadUrl(
        animalId,
        mimeType,
        fileSize,
      );
      return Right(data);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> confirmProfilePicture(
    String animalId,
    String finalUrl,
  ) async {
    try {
      await remoteDataSource.confirmProfilePicture(animalId, finalUrl);
      return const Right(null);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }
}
