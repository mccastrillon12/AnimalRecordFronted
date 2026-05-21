import 'package:dartz/dartz.dart';
import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/domain/repositories/animal_repository.dart';

class SearchAnimalsUseCase {
  final AnimalRepository repository;

  SearchAnimalsUseCase(this.repository);

  Future<Either<Failure, List<AnimalEntity>>> call(Map<String, dynamic> queryParams) async {
    return await repository.searchAnimals(queryParams);
  }
}
