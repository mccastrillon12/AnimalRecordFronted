import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../entities/register_params.dart';
import '../entities/login_params.dart';
import '../entities/verify_code_params.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp(RegisterParams params);
  Future<Either<Failure, UserEntity>> login(LoginParams params);
  Future<Either<Failure, void>> logout();
  Future<bool> isAuthenticated();
  Future<Either<Failure, void>> verifyCode(VerifyCodeParams params);
}
