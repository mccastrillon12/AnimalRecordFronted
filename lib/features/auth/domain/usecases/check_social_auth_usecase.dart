import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class CheckSocialAuthUseCase {
  final AuthRepository repository;

  CheckSocialAuthUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String provider,
    required String token,
  }) {
    return repository.checkSocialToken(provider, token);
  }
}
