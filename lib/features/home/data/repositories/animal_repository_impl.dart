import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
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
}
