import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';

abstract interface class MedicalDocumentsRepository {
  Future<MedicalDocumentEntity> analyze(AnalyzeMedicalDocumentRequest request);

  Future<MedicalDocumentEntity> getById(String documentId);

  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  );

  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  });

  Future<Uri> getDownloadUri(String documentId);
}
