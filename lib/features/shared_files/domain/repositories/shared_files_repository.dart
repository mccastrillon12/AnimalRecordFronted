import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';

abstract interface class SharedFilesRepository {
  Future<List<SharedFileEntity>> getInitialFiles();

  Stream<List<SharedFileEntity>> observeIncomingFiles();
}
