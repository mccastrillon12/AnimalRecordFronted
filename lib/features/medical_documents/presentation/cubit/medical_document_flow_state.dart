import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:equatable/equatable.dart';

enum MedicalDocumentFlowPhase {
  selecting,
  uploading,
  analyzing,
  pollingPaused,
  reviewing,
  submitting,
  rejecting,
  completed,
  rejected,
  failed,
}

class MedicalDocumentFlowState extends Equatable {
  final MedicalDocumentFlowPhase phase;
  final SharedFileEntity? sourceFile;
  final List<String> animalIds;
  final MedicalDocumentCategory? requestedCategory;
  final MedicalDocumentEntity? remoteDocument;
  final MedicalDocumentCategory? selectedFinalCategory;
  final MedicalDocumentCategory? selectedExtractionCategory;
  final MedicalDocumentExtractionEntity? draftExtraction;
  final Map<String, List<String>> assignmentsByAnimalId;
  final String? message;
  final bool versionConflict;

  const MedicalDocumentFlowState({
    this.phase = MedicalDocumentFlowPhase.selecting,
    this.sourceFile,
    this.animalIds = const [],
    this.requestedCategory,
    this.remoteDocument,
    this.selectedFinalCategory,
    this.selectedExtractionCategory,
    this.draftExtraction,
    this.assignmentsByAnimalId = const {},
    this.message,
    this.versionConflict = false,
  });

  bool get isBusy =>
      phase == MedicalDocumentFlowPhase.uploading ||
      phase == MedicalDocumentFlowPhase.analyzing ||
      phase == MedicalDocumentFlowPhase.submitting ||
      phase == MedicalDocumentFlowPhase.rejecting;

  MedicalDocumentFlowState copyWith({
    MedicalDocumentFlowPhase? phase,
    SharedFileEntity? sourceFile,
    List<String>? animalIds,
    MedicalDocumentCategory? requestedCategory,
    MedicalDocumentEntity? remoteDocument,
    MedicalDocumentCategory? selectedFinalCategory,
    MedicalDocumentCategory? selectedExtractionCategory,
    MedicalDocumentExtractionEntity? draftExtraction,
    Map<String, List<String>>? assignmentsByAnimalId,
    String? message,
    bool clearMessage = false,
    bool? versionConflict,
  }) {
    return MedicalDocumentFlowState(
      phase: phase ?? this.phase,
      sourceFile: sourceFile ?? this.sourceFile,
      animalIds: animalIds ?? this.animalIds,
      requestedCategory: requestedCategory ?? this.requestedCategory,
      remoteDocument: remoteDocument ?? this.remoteDocument,
      selectedFinalCategory:
          selectedFinalCategory ?? this.selectedFinalCategory,
      selectedExtractionCategory:
          selectedExtractionCategory ?? this.selectedExtractionCategory,
      draftExtraction: draftExtraction ?? this.draftExtraction,
      assignmentsByAnimalId:
          assignmentsByAnimalId ?? this.assignmentsByAnimalId,
      message: clearMessage ? null : message ?? this.message,
      versionConflict: versionConflict ?? this.versionConflict,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    sourceFile,
    animalIds,
    requestedCategory,
    remoteDocument,
    selectedFinalCategory,
    selectedExtractionCategory,
    draftExtraction,
    assignmentsByAnimalId,
    message,
    versionConflict,
  ];
}
