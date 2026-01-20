import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';
import '../entities/verify_code_params.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(VerifyCodeParams params) async {
    return await repository.verifyCode(params);
  }
}
