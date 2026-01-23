import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class CheckIdentificationExistsUseCase {
  final AuthRepository repository;

  CheckIdentificationExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String identificationNumber) async {
    return await repository.checkIdentificationExists(identificationNumber);
  }
}
