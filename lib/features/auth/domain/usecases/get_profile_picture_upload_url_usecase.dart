import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class GetProfilePictureUploadUrlUseCase {
  final AuthRepository repository;

  GetProfilePictureUploadUrlUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String mimeType,
    required int fileSize,
  }) {
    return repository.getProfilePictureUploadUrl(mimeType, fileSize);
  }
}
