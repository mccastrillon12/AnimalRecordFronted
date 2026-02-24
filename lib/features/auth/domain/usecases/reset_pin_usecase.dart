import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ResetPinUseCase {
  final AuthRepository repository;

  ResetPinUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String identifier,
    String token,
    String newPin,
  ) async {
    return await repository.resetPin(identifier, token, newPin);
  }
}
