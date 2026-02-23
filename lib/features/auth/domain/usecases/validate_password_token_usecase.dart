import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ValidatePasswordTokenUseCase {
  final AuthRepository repository;

  ValidatePasswordTokenUseCase(this.repository);

  Future<Either<Failure, bool>> call(String identifier, String token) async {
    return await repository.validatePasswordToken(identifier, token);
  }
}
