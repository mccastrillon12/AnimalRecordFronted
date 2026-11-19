import '../entities/medical_document_entity.dart';

class PendingMedicalDocumentFlow {
  final String documentId;
  final List<String> animalIds;
  final DateTime startedAt;
  final MedicalDocumentCategory? requestedCategory;

  const PendingMedicalDocumentFlow({
    required this.documentId,
    required this.animalIds,
    required this.startedAt,
    this.requestedCategory,
  });
}

abstract interface class PendingMedicalDocumentStore {
  Future<void> save(PendingMedicalDocumentFlow flow);
  PendingMedicalDocumentFlow? read();
  Future<void> clear();
}
