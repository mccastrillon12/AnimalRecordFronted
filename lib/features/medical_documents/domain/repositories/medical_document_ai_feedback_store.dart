import '../entities/medical_document_entity.dart';

abstract interface class MedicalDocumentAiFeedbackStore {
  bool isPending(String animalId, MedicalDocumentCategory category);

  Future<void> markPending(String animalId, MedicalDocumentCategory category);

  Future<void> clearPending(String animalId, MedicalDocumentCategory category);
}
