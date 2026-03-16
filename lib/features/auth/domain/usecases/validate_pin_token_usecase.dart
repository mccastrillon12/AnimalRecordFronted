import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ValidatePinTokenUseCase {
  final AuthRepository repository;

  ValidatePinTokenUseCase(this.repository);

  Future<Either<Failure, bool>> call(String identifier, String token) async {
    return await repository.validatePinToken(identifier, token);
  }
}
