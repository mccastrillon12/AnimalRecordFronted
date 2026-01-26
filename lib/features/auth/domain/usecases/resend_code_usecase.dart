import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ResendCodeUseCase {
  final AuthRepository repository;

  ResendCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String identifier) async {
    return await repository.resendVerificationCode(identifier);
  }
}
