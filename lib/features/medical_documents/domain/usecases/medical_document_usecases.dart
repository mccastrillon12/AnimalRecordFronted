import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_contract_validator.dart';

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
