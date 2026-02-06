import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class SavePinUseCase {
  final AuthRepository repository;

  SavePinUseCase(this.repository);

  Future<Either<Failure, void>> call(String pin) async {
    return await repository.savePin(pin);
  }
}
