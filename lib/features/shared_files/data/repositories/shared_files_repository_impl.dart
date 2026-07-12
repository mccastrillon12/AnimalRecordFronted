import 'package:animal_record/features/shared_files/data/datasources/shared_files_platform_datasource.dart';
import 'package:animal_record/features/shared_files/data/datasources/manual_file_picker_datasource.dart';
import 'package:animal_record/features/shared_files/data/models/shared_file_model.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:animal_record/features/shared_files/domain/repositories/shared_files_repository.dart';

class SharedFilesRepositoryImpl implements SharedFilesRepository {
  final SharedFilesPlatformDataSource platformDataSource;
  final ManualFilePickerDataSource manualFilePickerDataSource;

  const SharedFilesRepositoryImpl(
    this.platformDataSource,
    this.manualFilePickerDataSource,
  );

  @override
  Future<List<SharedFileEntity>> getInitialFiles() async {
    final files = await platformDataSource.getInitialFiles();
    return files.map(SharedFileModel.fromMap).toList(growable: false);
  }

  @override
  Stream<List<SharedFileEntity>> observeIncomingFiles() {
    return platformDataSource.observeIncomingFiles().map(
      (files) => files.map(SharedFileModel.fromMap).toList(growable: false),
    );
  }

  @override
  Future<SharedFileEntity?> pickManualFile() async {
    final file = await manualFilePickerDataSource.pickFile();
    return file == null ? null : SharedFileModel.fromMap(file);
  }
}
