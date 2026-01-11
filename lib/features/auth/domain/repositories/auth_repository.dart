import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../entities/register_params.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp(RegisterParams params);
}
