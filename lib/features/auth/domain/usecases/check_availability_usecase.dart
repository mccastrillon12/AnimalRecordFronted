import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class CheckAvailabilityUseCase {
  final AuthRepository repository;

  CheckAvailabilityUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(Map<String, dynamic> data) async {
    return await repository.checkAvailability(data);
  }
}
