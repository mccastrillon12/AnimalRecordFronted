import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class ObserveSharedFilesUseCase {
  final SharedFilesRepository repository;

  const ObserveSharedFilesUseCase(this.repository);

  Stream<List<SharedFileEntity>> call() => repository.observeIncomingFiles();
}
