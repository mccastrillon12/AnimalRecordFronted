import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/manual_file_source.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class ManualFileSelectionException implements Exception {
  final String message;

  const ManualFileSelectionException(this.message);

  @override
  String toString() => message;
}

class PickManualSharedFileUseCase {
  static const int maximumFileSize = 10 * 1024 * 1024;

  final SharedFilesRepository repository;

  const PickManualSharedFileUseCase(this.repository);

  Future<SharedFileEntity?> call(ManualFileSource source) async {
    final file = await repository.pickManualFile(source);
    if (file == null) return null;

    if (file.type == SharedFileType.unsupported) {
      throw const ManualFileSelectionException(
        'Selecciona un archivo PNG, JPG, JPEG, TIFF o PDF.',
      );
    }
    if (file.size > maximumFileSize) {
      throw const ManualFileSelectionException(
        'El archivo debe pesar máximo 10 MB.',
      );
    }
    return file;
  }
}
