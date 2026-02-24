import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class ForgotPinUseCase {
  final AuthRepository repository;

  ForgotPinUseCase(this.repository);

  Future<Either<Failure, void>> call(String params) async {
    return await repository.forgotPin(params);
  }
}
