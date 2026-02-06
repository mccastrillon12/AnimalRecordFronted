import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ChangePinUseCase {
  final AuthRepository repository;

  ChangePinUseCase(this.repository);

  Future<Either<Failure, void>> call(String oldPin, String newPin) async {
    return await repository.changePin(oldPin, newPin);
  }
}
