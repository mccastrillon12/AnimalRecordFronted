import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class ExportSharedFileAnalysisPdfUseCase {
  final SharedFilesRepository repository;

  const ExportSharedFileAnalysisPdfUseCase(this.repository);

  Future<void> call(SharedFileAnalysisEntity analysis) {
    return repository.exportAnalysisPdf(analysis);
  }
}
