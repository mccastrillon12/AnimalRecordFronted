import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

class UpdateBiometricStatusUseCase {
  final AuthRepository repository;
  UpdateBiometricStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(bool enabled) async {
    return await repository.updateBiometricStatus(enabled);
  }
}
