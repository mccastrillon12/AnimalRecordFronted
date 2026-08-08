import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';

class AnalyzeMedicalDocumentRequest {
  final SharedFileEntity file;
  final List<String> animalIds;
  final MedicalDocumentCategory? requestedCategory;

  const AnalyzeMedicalDocumentRequest({
    required this.file,
    required this.animalIds,
    this.requestedCategory,
  });
}

enum MedicalDocumentReviewDecision { accept, reject }

class ReviewMedicalDocumentRequest {
  final MedicalDocumentReviewDecision decision;
  final int documentVersion;
  final MedicalDocumentCategory? finalCategory;
  final MedicalDocumentExtractionEntity? validatedExtraction;
  final List<MedicalDocumentAssignmentEntity> assignments;

  const ReviewMedicalDocumentRequest._({
    required this.decision,
    required this.documentVersion,
    this.finalCategory,
    this.validatedExtraction,
    this.assignments = const [],
  });

  factory ReviewMedicalDocumentRequest.accept({
    required int documentVersion,
    required MedicalDocumentCategory finalCategory,
    required MedicalDocumentExtractionEntity validatedExtraction,
    required List<MedicalDocumentAssignmentEntity> assignments,
  }) => ReviewMedicalDocumentRequest._(
    decision: MedicalDocumentReviewDecision.accept,
    documentVersion: documentVersion,
    finalCategory: finalCategory,
    validatedExtraction: validatedExtraction,
    assignments: assignments,
  );

  factory ReviewMedicalDocumentRequest.reject({required int documentVersion}) =>
      ReviewMedicalDocumentRequest._(
        decision: MedicalDocumentReviewDecision.reject,
        documentVersion: documentVersion,
      );
}
