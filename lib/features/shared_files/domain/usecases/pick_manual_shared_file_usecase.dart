import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class ManualFileSelectionException implements Exception {
  final String message;

  const ManualFileSelectionException(this.message);

  @override
  String toString() => message;
}

class PickManualSharedFileUseCase {
  static const int maximumImageSize = 1024 * 1024;
  static const int maximumPdfSize = 5 * 1024 * 1024;

  final SharedFilesRepository repository;

  const PickManualSharedFileUseCase(this.repository);

  Future<SharedFileEntity?> call() async {
    final file = await repository.pickManualFile();
    if (file == null) return null;

    if (file.type == SharedFileType.unsupported) {
      throw const ManualFileSelectionException(
        'Selecciona un archivo PNG, JPG, JPEG o PDF.',
      );
    }
    if (file.type == SharedFileType.pdf && file.size > maximumPdfSize) {
      throw const ManualFileSelectionException(
        'El PDF debe pesar máximo 5 MB.',
      );
    }
    if (file.type == SharedFileType.image && file.size > maximumImageSize) {
      throw const ManualFileSelectionException(
        'La imagen debe pesar máximo 1 MB.',
      );
    }
    return file;
  }
}
