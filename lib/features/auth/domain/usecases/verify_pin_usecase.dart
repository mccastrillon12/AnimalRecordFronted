import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class VerifyPinUseCase {
  final AuthRepository repository;

  VerifyPinUseCase(this.repository);

  Future<Either<Failure, void>> call(String pin) async {
    return await repository.verifyPin(pin);
  }
}
