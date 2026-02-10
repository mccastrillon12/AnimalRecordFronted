import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

class GetBiometricStatusUseCase {
  final AuthRepository repository;
  GetBiometricStatusUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.getBiometricStatus();
  }
}
