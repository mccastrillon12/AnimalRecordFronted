import 'package:animal_record/features/home/domain/services/animal_write_access.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_documents_remote_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_write_access.dart';

class RemoteMedicalDocumentWriteAccess implements MedicalDocumentWriteAccess {
  final MedicalDocumentsRemoteDataSource remote;
  final AnimalWriteAccess animalWriteAccess;

  const RemoteMedicalDocumentWriteAccess(this.remote, this.animalWriteAccess);

  @override
  Future<void> ensureWritable({
    Iterable<String> animalIds = const [],
    Iterable<String> documentIds = const [],
  }) async {
    final affected = animalIds.toSet();
    for (final id in documentIds.toSet()) {
      final document = await remote.getById(id);
      if (document.readOnly) throw const AnimalReadOnlyException();
      affected.addAll(document.animalIds);
    }
    await animalWriteAccess.ensureWritable(affected);
  }
}
