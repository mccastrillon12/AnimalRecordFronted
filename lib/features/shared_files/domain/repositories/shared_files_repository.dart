import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/manual_file_source.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';

abstract interface class SharedFilesRepository {
  Future<List<SharedFileEntity>> getInitialFiles();

  Stream<List<SharedFileEntity>> observeIncomingFiles();

  Future<SharedFileEntity?> pickManualFile(ManualFileSource source);

  Future<void> exportAnalysisPdf(SharedFileAnalysisEntity analysis);

  Future<bool> saveAnalysisPdfs(
    List<SharedFileAnalysisEntity> analyses, {
    required String fileName,
  });
}
