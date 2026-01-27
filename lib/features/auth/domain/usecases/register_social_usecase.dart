import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterSocialUseCase {
  final AuthRepository repository;

  RegisterSocialUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(Map<String, dynamic> data) {
    return repository.registerSocial(data);
  }
}
