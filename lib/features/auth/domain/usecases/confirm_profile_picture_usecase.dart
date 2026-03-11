import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ConfirmProfilePictureUseCase {
  final AuthRepository repository;

  ConfirmProfilePictureUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String finalUrl) {
    return repository.confirmProfilePicture(finalUrl);
  }
}
