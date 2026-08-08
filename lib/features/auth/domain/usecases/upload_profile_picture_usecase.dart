import 'package:animal_record/core/errors/failure.dart';
import 'package:animal_record/core/services/file_uploader.dart';
import 'package:animal_record/core/services/media_file_service.dart';
import 'package:animal_record/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class UploadProfilePictureUseCase {
  static const _mimeType = 'image/jpeg';

  final AuthRepository repository;
  final MediaFileService mediaFileService;
  final FileUploader fileUploader;

  const UploadProfilePictureUseCase({
    required this.repository,
    required this.mediaFileService,
    required this.fileUploader,
  });

  Future<Either<Failure, String>> call(String imagePath) async {
    try {
      final compressedBytes = await mediaFileService.compressImage(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      );

      if (compressedBytes == null) {
        return const Left(ServerFailure('No se pudo comprimir la imagen'));
      }

      final urlResult = await repository.getProfilePictureUploadUrl(
        _mimeType,
        compressedBytes.length,
      );

      return await urlResult.fold<Future<Either<Failure, String>>>(
        (failure) async => Left(failure),
        (urlData) async {
          final uploadUrl = urlData['uploadUrl'] as String?;
          final finalUrl = urlData['finalUrl'] as String?;

          if (uploadUrl == null || finalUrl == null) {
            return const Left(ServerFailure('Respuesta inválida del servidor'));
          }

          await fileUploader.upload(
            uploadUrl: uploadUrl,
            bytes: compressedBytes,
            mimeType: _mimeType,
          );

          final confirmResult = await repository.confirmProfilePicture(
            finalUrl,
          );

          return confirmResult.fold<Either<Failure, String>>(
            Left.new,
            (_) => Right(finalUrl),
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
