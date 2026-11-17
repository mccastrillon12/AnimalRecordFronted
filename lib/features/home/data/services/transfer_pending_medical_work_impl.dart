import 'package:animal_record/features/home/domain/services/transfer_pending_medical_work.dart';
import 'package:animal_record/features/medical_documents/data/datasources/pending_medical_document_local_datasource.dart';

class TransferPendingMedicalWorkImpl implements TransferPendingMedicalWork {
  final PendingMedicalDocumentLocalDataSource source;
  const TransferPendingMedicalWorkImpl(this.source);

  @override
  bool overlaps(List<String> animalIds) {
    final pending = source.read();
    if (pending == null) return false;
    final selected = animalIds.toSet();
    return pending.animalIds.any(selected.contains);
  }
}
