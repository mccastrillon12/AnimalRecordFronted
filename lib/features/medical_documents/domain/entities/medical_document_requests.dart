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

class AnalyzeMedicalDocumentReplacementRequest {
  final SharedFileEntity file;
  final int documentVersion;
  final List<String> animalIds;
  final String? description;

  const AnalyzeMedicalDocumentReplacementRequest({
    required this.file,
    required this.documentVersion,
    required this.animalIds,
    this.description,
  });
}

class MedicalDocumentVersion {
  final String documentId;
  final int version;

  const MedicalDocumentVersion({
    required this.documentId,
    required this.version,
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

class ReviewMedicalDocumentReplacementRequest {
  final MedicalDocumentReviewDecision decision;
  final String candidateDocumentId;
  final int documentVersion;
  final int candidateVersion;
  final List<MedicalDocumentVersion> documentVersions;
  final MedicalDocumentCategory? finalCategory;
  final MedicalDocumentExtractionEntity? validatedExtraction;
  final List<MedicalDocumentAssignmentEntity> assignments;

  const ReviewMedicalDocumentReplacementRequest._({
    required this.decision,
    required this.candidateDocumentId,
    required this.documentVersion,
    required this.candidateVersion,
    this.documentVersions = const [],
    this.finalCategory,
    this.validatedExtraction,
    this.assignments = const [],
  });

  factory ReviewMedicalDocumentReplacementRequest.accept({
    required String candidateDocumentId,
    required int documentVersion,
    required int candidateVersion,
    required List<MedicalDocumentVersion> documentVersions,
    required MedicalDocumentCategory finalCategory,
    required MedicalDocumentExtractionEntity validatedExtraction,
    required List<MedicalDocumentAssignmentEntity> assignments,
  }) => ReviewMedicalDocumentReplacementRequest._(
    decision: MedicalDocumentReviewDecision.accept,
    candidateDocumentId: candidateDocumentId,
    documentVersion: documentVersion,
    candidateVersion: candidateVersion,
    documentVersions: documentVersions,
    finalCategory: finalCategory,
    validatedExtraction: validatedExtraction,
    assignments: assignments,
  );

  factory ReviewMedicalDocumentReplacementRequest.reject({
    required String candidateDocumentId,
    required int documentVersion,
    required int candidateVersion,
  }) => ReviewMedicalDocumentReplacementRequest._(
    decision: MedicalDocumentReviewDecision.reject,
    candidateDocumentId: candidateDocumentId,
    documentVersion: documentVersion,
    candidateVersion: candidateVersion,
  );
}
