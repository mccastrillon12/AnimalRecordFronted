import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_contract_validator.dart';

class GetMedicalFieldCatalogUseCase {
  final MedicalDocumentsRepository repository;

  const GetMedicalFieldCatalogUseCase(this.repository);

  Future<MedicalFieldCatalog> call({
    required MedicalDocumentCategory category,
    String locale = 'es-CO',
  }) => repository.getFieldCatalog(category: category, locale: locale);
}

class AnalyzeMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const AnalyzeMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(AnalyzeMedicalDocumentRequest request) {
    MedicalDocumentContractValidator.validateAnalysis(
      file: request.file,
      animalIds: request.animalIds,
    );
    return repository.analyze(request);
  }
}

class GetMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const GetMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(String documentId) =>
      repository.getById(documentId);
}

class GetMedicalDocumentRejectionReasonsUseCase {
  final MedicalDocumentsRepository repository;

  const GetMedicalDocumentRejectionReasonsUseCase(this.repository);

  Future<List<MedicalDocumentRejectionReasonEntity>> call() =>
      repository.getRejectionReasons();
}

class SubmitMedicalDocumentAiFeedbackUseCase {
  final MedicalDocumentsRepository repository;

  const SubmitMedicalDocumentAiFeedbackUseCase(this.repository);

  Future<void> call(MedicalDocumentAiFeedback feedback) =>
      repository.submitAiFeedback(feedback);
}

class ReviewMedicalDocumentUseCase {
  final MedicalDocumentsRepository repository;
  const ReviewMedicalDocumentUseCase(this.repository);
  Future<MedicalDocumentEntity> call(
    String documentId,
    ReviewMedicalDocumentRequest request, {
    required List<String> originalAnimalIds,
  }) {
    MedicalDocumentContractValidator.validateReview(
      request: request,
      originalAnimalIds: originalAnimalIds,
    );
    return repository.review(documentId, request);
  }
}

class GetAnimalMedicalDocumentsUseCase {
  final MedicalDocumentsRepository repository;
  const GetAnimalMedicalDocumentsUseCase(this.repository);
  Future<List<MedicalDocumentEntity>> call(
    String animalId, {
    MedicalDocumentCategory? category,
    bool forceRefresh = false,
  }) => repository.getByAnimal(
    animalId,
    category: category,
    forceRefresh: forceRefresh,
  );
}

class GetMedicalDocumentDownloadUriUseCase {
  final MedicalDocumentsRepository repository;
  const GetMedicalDocumentDownloadUriUseCase(this.repository);
  Future<Uri> call(String documentId) => repository.getDownloadUri(documentId);
}

class SaveMedicalDocumentOriginalUseCase {
  final MedicalDocumentFileSaver fileSaver;

  const SaveMedicalDocumentOriginalUseCase(this.fileSaver);

  Future<bool> call(MedicalDocumentFileSaveRequest request) {
    return fileSaver.save(request);
  }
}
