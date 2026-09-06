import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';

class AnalyzeMedicalDocumentRequest {
  final SharedFileEntity file;
  final List<String> animalIds;
  final MedicalDocumentCategory? requestedCategory;
  final String? description;

  const AnalyzeMedicalDocumentRequest({
    required this.file,
    required this.animalIds,
    this.requestedCategory,
    this.description,
  });
}

enum MedicalDocumentReviewDecision { accept, reject }

class ReviewMedicalDocumentRequest {
  final MedicalDocumentReviewDecision decision;
  final int documentVersion;
  final String? rejectionReasonCode;
  final String? rejectionComment;
  final MedicalDocumentCategory? finalCategory;
  final MedicalDocumentExtractionEntity? validatedExtraction;
  final List<MedicalDocumentAssignmentEntity> assignments;

  const ReviewMedicalDocumentRequest._({
    required this.decision,
    required this.documentVersion,
    this.rejectionReasonCode,
    this.rejectionComment,
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

  factory ReviewMedicalDocumentRequest.reject({
    required int documentVersion,
    String? rejectionReasonCode,
    String? rejectionComment,
  }) => ReviewMedicalDocumentRequest._(
    decision: MedicalDocumentReviewDecision.reject,
    documentVersion: documentVersion,
    rejectionReasonCode: rejectionReasonCode,
    rejectionComment: rejectionComment,
  );
}
