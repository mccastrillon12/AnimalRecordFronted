import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';

abstract interface class MedicalDocumentsRepository {
  Future<MedicalDocumentEntity> analyze(AnalyzeMedicalDocumentRequest request);

  Future<MedicalDocumentEntity> getById(String documentId);

  Future<List<MedicalDocumentRejectionReasonEntity>> getRejectionReasons();

  Future<void> submitAiFeedback(MedicalDocumentAiFeedback feedback);

  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  );

  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
    bool forceRefresh = false,
  });

  void clearCache();

  Future<Uri> getDownloadUri(String documentId);
}
