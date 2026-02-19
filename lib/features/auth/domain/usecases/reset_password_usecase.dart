import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String identifier,
    String token,
    String newPassword,
  ) {
    return repository.resetPassword(identifier, token, newPassword);
  }
}
