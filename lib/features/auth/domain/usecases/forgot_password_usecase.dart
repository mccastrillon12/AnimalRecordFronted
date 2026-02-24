import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String identifier) async {
    return await repository.forgotPassword(identifier);
  }
}
