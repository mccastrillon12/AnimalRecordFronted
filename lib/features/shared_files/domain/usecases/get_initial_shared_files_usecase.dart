import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class GetInitialSharedFilesUseCase {
  final SharedFilesRepository repository;

  const GetInitialSharedFilesUseCase(this.repository);

  Future<List<SharedFileEntity>> call() => repository.getInitialFiles();
}
