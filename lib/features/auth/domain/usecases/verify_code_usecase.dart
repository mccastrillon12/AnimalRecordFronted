import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';
import '../entities/verify_code_params.dart';

import '../entities/user_entity.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(VerifyCodeParams params) async {
    return await repository.verifyCode(params);
  }
}
