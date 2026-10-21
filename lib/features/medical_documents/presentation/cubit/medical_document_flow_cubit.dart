import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/medical_documents/data/datasources/pending_medical_document_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

typedef MedicalDocumentPollDelay = Future<void> Function(Duration duration);
typedef MedicalDocumentItemIdGenerator = String Function();

class MedicalDocumentFlowCubit extends Cubit<MedicalDocumentFlowState> {
  static const pollDelays = [
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  final AnalyzeMedicalDocumentUseCase analyzeUseCase;
  final AnalyzeMedicalDocumentReplacementUseCase? analyzeReplacementUseCase;
  final GetMedicalDocumentUseCase getDocumentUseCase;
  final GetRelatedMedicalDocumentsUseCase? getRelatedDocumentsUseCase;
  final ReviewMedicalDocumentUseCase reviewUseCase;
  final ReviewMedicalDocumentReplacementUseCase? reviewReplacementUseCase;
  final PendingMedicalDocumentLocalDataSource pendingLocalDataSource;
  final MedicalDocumentPollDelay pollDelay;
  final MedicalDocumentItemIdGenerator itemIdGenerator;

  int _pollGeneration = 0;
  bool _polling = false;
  Future<void>? _pollCompletion;

  PendingMedicalDocumentFlow? get pendingFlow => pendingLocalDataSource.read();

  MedicalDocumentFlowCubit({
    required this.analyzeUseCase,
    this.analyzeReplacementUseCase,
    required this.getDocumentUseCase,
    this.getRelatedDocumentsUseCase,
    required this.reviewUseCase,
    this.reviewReplacementUseCase,
    required this.pendingLocalDataSource,
    MedicalDocumentPollDelay? pollDelay,
    MedicalDocumentItemIdGenerator? itemIdGenerator,
  }) : pollDelay = pollDelay ?? Future<void>.delayed,
       itemIdGenerator = itemIdGenerator ?? const Uuid().v4,
       super(const MedicalDocumentFlowState());

  void initializeReplacement({
    required MedicalDocumentEntity anchor,
    required List<MedicalDocumentEntity> relatedDocuments,
  }) {
    final immutableRelated = List<MedicalDocumentEntity>.unmodifiable(
      relatedDocuments,
    );
    final editableAnimalIds = _editableReplacementAnimalIds(
      anchor,
      immutableRelated,
    );
    final anchorAnimalIds = anchor.animalIds
        .where(editableAnimalIds.contains)
        .toList(growable: false);
    final selectedAnimalIds = anchorAnimalIds.isNotEmpty
        ? anchorAnimalIds
        : editableAnimalIds.isEmpty
        ? const <String>[]
        : <String>[editableAnimalIds.first];

    emit(
      MedicalDocumentFlowState(
        phase: MedicalDocumentFlowPhase.selecting,
        animalIds: List.unmodifiable(selectedAnimalIds),
        selectedFinalCategory: anchor.finalCategory,
        selectedExtractionCategory: anchor.validatedExtraction?.documentType,
        replacementAnchor: anchor,
        relatedDocuments: immutableRelated,
      ),
    );
  }

  void selectReplacementAnimalIds(List<String> animalIds) {
    final anchor = state.replacementAnchor;
    if (anchor == null) return;
    final editableIds = _editableReplacementAnimalIds(
      anchor,
      state.relatedDocuments,
    ).toSet();
    final selected = animalIds
        .where(editableIds.contains)
        .toSet()
        .toList(growable: false);
    emit(
      state.copyWith(
        animalIds: List.unmodifiable(selected),
        assignmentsByAnimalId: {
          for (final animalId in selected)
            animalId: state.assignmentsByAnimalId[animalId] ?? const [],
        },
        clearMessage: true,
        versionConflict: false,
      ),
    );
  }

  Future<void> startReplacementAnalysis({
    required SharedFileEntity file,
    required List<String> animalIds,
    String? description,
    bool recoverActiveCandidate = true,
  }) async {
    final anchor = state.replacementAnchor;
    final analyzeReplacement = analyzeReplacementUseCase;
    if (anchor == null || analyzeReplacement == null) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.failed,
          message: 'No fue posible iniciar la edición del archivo.',
        ),
      );
      return;
    }

    selectReplacementAnimalIds(animalIds);
    final selectedAnimalIds = state.animalIds;
    if (selectedAnimalIds.isEmpty) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.selecting,
          message: 'Selecciona al menos un animal para continuar.',
        ),
      );
      return;
    }

    final analysisGeneration = ++_pollGeneration;
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.uploading,
        sourceFile: file,
        clearMessage: true,
        versionConflict: false,
      ),
    );
    try {
      final candidate = await analyzeReplacement(
        anchor.id,
        AnalyzeMedicalDocumentReplacementRequest(
          file: file,
          documentVersion: anchor.version,
          animalIds: selectedAnimalIds,
          description: description?.trim().isNotEmpty == true
              ? description!.trim()
              : null,
        ),
      );
      if (analysisGeneration != _pollGeneration || isClosed) return;
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.analyzing,
          remoteDocument: candidate,
          clearMessage: true,
        ),
      );
      await _poll(candidate.id);
    } on ApiException catch (error) {
      if (analysisGeneration != _pollGeneration || isClosed) return;
      if (error.statusCode == 409) {
        final activeCandidateId = _activeReplacementCandidateId(error);
        if (recoverActiveCandidate &&
            activeCandidateId != null &&
            await _rejectActiveReplacementCandidate(activeCandidateId)) {
          if (isClosed) return;
          await startReplacementAnalysis(
            file: file,
            animalIds: selectedAnimalIds,
            description: description,
            recoverActiveCandidate: false,
          );
          return;
        }
        await _refreshReplacementAfterConflict(
          candidateDocumentId: activeCandidateId,
          fallbackPhase: MedicalDocumentFlowPhase.selecting,
        );
      } else {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.failed,
            message: _message(error),
          ),
        );
      }
    } catch (error) {
      if (analysisGeneration != _pollGeneration || isClosed) return;
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.failed,
          message: _message(error),
        ),
      );
    }
  }

  String? _activeReplacementCandidateId(ApiException error) {
    final pattern = RegExp(
      r'Replacement analysis\s+([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\s+is already active',
      caseSensitive: false,
    );
    final responseData = error.data;
    final serverMessage = responseData is Map
        ? responseData['message']?.toString()
        : null;
    for (final message in [serverMessage, error.message]) {
      if (message == null) continue;
      final match = pattern.firstMatch(message);
      if (match != null) return match.group(1);
    }
    return null;
  }

  Future<bool> _rejectActiveReplacementCandidate(String candidateId) async {
    final generation = ++_pollGeneration;
    var attempt = 0;
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.analyzing,
        clearMessage: true,
      ),
    );
    try {
      while (!isClosed && generation == _pollGeneration) {
        final candidate = await getDocumentUseCase(candidateId);
        if (isClosed || generation != _pollGeneration) return false;
        if (candidate.status == MedicalDocumentStatus.pendingUpload ||
            candidate.status == MedicalDocumentStatus.analyzing) {
          emit(
            state.copyWith(
              phase: MedicalDocumentFlowPhase.analyzing,
              remoteDocument: candidate,
              clearMessage: true,
            ),
          );
          final delay = pollDelays[attempt.clamp(0, pollDelays.length - 1)];
          attempt++;
          await pollDelay(delay);
          continue;
        }
        if (candidate.status == MedicalDocumentStatus.reviewPending) {
          emit(
            state.copyWith(
              phase: MedicalDocumentFlowPhase.analyzing,
              remoteDocument: candidate,
              clearMessage: true,
            ),
          );
          await _rejectReplacement(showSubmittingState: false);
          return !isClosed && state.phase == MedicalDocumentFlowPhase.rejected;
        }
        return candidate.status == MedicalDocumentStatus.rejected ||
            candidate.status == MedicalDocumentStatus.failed;
      }
    } catch (error) {
      if (!isClosed && generation == _pollGeneration) {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.selecting,
            message: _message(error),
          ),
        );
      }
    }
    return false;
  }

  Future<void> startAnalysis({
    required SharedFileEntity file,
    required List<String> animalIds,
    MedicalDocumentCategory? requestedCategory,
    String? description,
  }) async {
    final analysisGeneration = ++_pollGeneration;
    emit(
      MedicalDocumentFlowState(
        phase: MedicalDocumentFlowPhase.uploading,
        sourceFile: file,
        animalIds: List.unmodifiable(animalIds),
        requestedCategory: requestedCategory,
      ),
    );
    try {
      final document = await analyzeUseCase(
        AnalyzeMedicalDocumentRequest(
          file: file,
          animalIds: animalIds,
          requestedCategory: requestedCategory,
          description: description?.trim().isNotEmpty == true
              ? description!.trim()
              : null,
        ),
      );
      if (analysisGeneration != _pollGeneration || isClosed) return;
      await pendingLocalDataSource.save(
        PendingMedicalDocumentFlow(
          documentId: document.id,
          animalIds: animalIds,
          startedAt: DateTime.now(),
          requestedCategory: requestedCategory,
        ),
      );
      if (analysisGeneration != _pollGeneration || isClosed) {
        await pendingLocalDataSource.clear();
        return;
      }
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.analyzing,
          remoteDocument: document,
          clearMessage: true,
        ),
      );
      await _poll(document.id);
    } catch (error) {
      if (analysisGeneration != _pollGeneration || isClosed) return;
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.failed,
          message: _message(error),
        ),
      );
    }
  }

  Future<bool> resumePending() async {
    final pending = pendingLocalDataSource.read();
    if (pending == null) return false;
    emit(
      MedicalDocumentFlowState(
        phase: MedicalDocumentFlowPhase.analyzing,
        animalIds: pending.animalIds,
        requestedCategory: pending.requestedCategory,
      ),
    );
    await _poll(pending.documentId, pollImmediately: true);
    return true;
  }

  Future<void> _poll(String documentId, {bool pollImmediately = false}) async {
    if (_polling) await _pollCompletion;
    if (isClosed) return;
    final completion = Completer<void>();
    _polling = true;
    _pollCompletion = completion.future;
    final generation = ++_pollGeneration;
    var attempt = 0;
    try {
      if (!pollImmediately) await pollDelay(const Duration(seconds: 1));
      while (!isClosed && generation == _pollGeneration) {
        final document = await getDocumentUseCase(documentId);
        if (generation != _pollGeneration || isClosed) return;
        if (document.status == MedicalDocumentStatus.analyzing ||
            document.status == MedicalDocumentStatus.pendingUpload) {
          emit(
            state.copyWith(
              phase: MedicalDocumentFlowPhase.analyzing,
              remoteDocument: document,
              clearMessage: true,
            ),
          );
          final delay = pollDelays[attempt.clamp(0, pollDelays.length - 1)];
          attempt++;
          await pollDelay(delay);
          continue;
        }
        await _applyTerminalOrReviewState(document);
        return;
      }
    } catch (error) {
      if (!isClosed && generation == _pollGeneration) {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.pollingPaused,
            message:
                'Se interrumpió la consulta del análisis. Puedes reintentar sin volver a subir el archivo. ${_message(error)}',
          ),
        );
      }
    } finally {
      _polling = false;
      if (!completion.isCompleted) completion.complete();
      if (identical(_pollCompletion, completion.future)) {
        _pollCompletion = null;
      }
    }
  }

  Future<void> _applyTerminalOrReviewState(
    MedicalDocumentEntity document,
  ) async {
    switch (document.status) {
      case MedicalDocumentStatus.reviewPending:
        final category = state.isReplacement
            ? state.replacementAnchor?.finalCategory ??
                  _suggestedCategory(document)
            : _suggestedCategory(document);
        _emitReview(document, category);
      case MedicalDocumentStatus.accepted:
        await pendingLocalDataSource.clear();
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.completed,
            remoteDocument: document,
            clearMessage: true,
          ),
        );
      case MedicalDocumentStatus.rejected:
        await pendingLocalDataSource.clear();
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.rejected,
            remoteDocument: document,
            clearMessage: true,
          ),
        );
      case MedicalDocumentStatus.failed:
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.failed,
            remoteDocument: document,
            message: 'No fue posible analizar el archivo.',
          ),
        );
      case MedicalDocumentStatus.pendingUpload:
      case MedicalDocumentStatus.analyzing:
        break;
    }
  }

  MedicalDocumentCategory _suggestedCategory(MedicalDocumentEntity document) {
    return switch (document.classificationOutcome) {
      MedicalDocumentClassificationOutcome.match ||
      MedicalDocumentClassificationOutcome.matchWithAdditional =>
        document.requestedCategory ??
            document.primaryDetectedCategory ??
            MedicalDocumentCategory.other,
      _ =>
        document.primaryDetectedCategory ??
            document.detectedCategories.firstOrNull?.category ??
            MedicalDocumentCategory.other,
    };
  }

  void selectFinalCategory(MedicalDocumentCategory category) {
    final document = state.remoteDocument;
    if (document == null) return;
    emit(
      state.copyWith(
        selectedFinalCategory: category,
        clearMessage: true,
        versionConflict: false,
      ),
    );
  }

  /// Changes the reviewed extraction only through a separate explicit action.
  /// Selecting where the file is archived never invokes this method.
  void useExtractionCategory(MedicalDocumentCategory category) {
    final document = state.remoteDocument;
    final extraction = document?.extractionsByCategory[category];
    if (document == null || extraction == null) return;
    final draft = extraction;
    emit(
      state.copyWith(
        selectedExtractionCategory: category,
        draftExtraction: draft,
        assignmentsByAnimalId: {
          for (final animalId in document.animalIds)
            animalId: List.unmodifiable(draft.extractedItemIds),
        },
        clearMessage: true,
        versionConflict: false,
      ),
    );
  }

  void _emitReview(
    MedicalDocumentEntity document,
    MedicalDocumentCategory category,
  ) {
    final draft = _reviewExtraction(document, category);
    final assignmentAnimalIds = state.isReplacement
        ? state.animalIds
        : document.animalIds;
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.reviewing,
        remoteDocument: document,
        selectedFinalCategory: category,
        selectedExtractionCategory: draft.documentType,
        draftExtraction: draft,
        assignmentsByAnimalId: {
          for (final animalId in assignmentAnimalIds)
            animalId: List.unmodifiable(draft.extractedItemIds),
        },
        clearMessage: true,
        versionConflict: false,
      ),
    );
  }

  MedicalDocumentExtractionEntity _reviewExtraction(
    MedicalDocumentEntity document,
    MedicalDocumentCategory category,
  ) {
    return document.validatedExtraction ??
        document.extractionsByCategory[document.primaryDetectedCategory] ??
        document.extractionsByCategory[category] ??
        document.extractionsByCategory.values.firstOrNull ??
        MedicalDocumentExtractionEntity.empty(MedicalDocumentCategory.other);
  }

  void updateDraft(MedicalDocumentExtractionEntity extraction) {
    if (state.selectedFinalCategory == null) return;
    final validIds = extraction.extractedItemIds.toSet();
    emit(
      state.copyWith(
        draftExtraction: extraction,
        assignmentsByAnimalId: {
          for (final entry in state.assignmentsByAnimalId.entries)
            entry.key: entry.value
                .where(validIds.contains)
                .toList(growable: false),
        },
        versionConflict: false,
      ),
    );
  }

  String createDraftItemId() => itemIdGenerator();

  void updateAssignment(String animalId, List<String> extractedItemIds) {
    final validIds = state.draftExtraction?.extractedItemIds.toSet() ?? {};
    emit(
      state.copyWith(
        assignmentsByAnimalId: {
          ...state.assignmentsByAnimalId,
          animalId: extractedItemIds
              .where(validIds.contains)
              .toSet()
              .toList(growable: false),
        },
      ),
    );
  }

  Future<void> accept() async {
    if (state.isReplacement) {
      await _acceptReplacement();
      return;
    }
    final document = state.remoteDocument;
    final category = state.selectedFinalCategory;
    final extraction = state.draftExtraction;
    if (document == null || category == null || extraction == null) return;
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.submitting,
        clearMessage: true,
      ),
    );
    try {
      final request = ReviewMedicalDocumentRequest.accept(
        documentVersion: document.version,
        finalCategory: category,
        validatedExtraction: extraction,
        assignments: document.animalIds
            .map(
              (animalId) => MedicalDocumentAssignmentEntity(
                animalId: animalId,
                extractedItemIds:
                    state.assignmentsByAnimalId[animalId] ?? const [],
              ),
            )
            .toList(growable: false),
      );
      final reviewed = await reviewUseCase(
        document.id,
        request,
        originalAnimalIds: document.animalIds,
      );
      await _applyTerminalOrReviewState(reviewed);
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _handleVersionConflict(document.id);
      } else {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            message: error.message,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message: _message(error),
        ),
      );
    }
  }

  Future<void> _handleVersionConflict(String documentId) async {
    try {
      final current = await getDocumentUseCase(documentId);
      if (current.status == MedicalDocumentStatus.reviewPending) {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            remoteDocument: current,
            versionConflict: true,
            message:
                'El archivo cambió en el servidor. Revisa los datos y confirma nuevamente.',
          ),
        );
      } else {
        await _applyTerminalOrReviewState(current);
      }
    } catch (error) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message: _message(error),
        ),
      );
    }
  }

  Future<void> reject({String? reasonCode, String? comment}) async {
    if (state.isReplacement) {
      await _rejectReplacement();
      return;
    }
    final document = state.remoteDocument;
    if (document == null ||
        document.status != MedicalDocumentStatus.reviewPending) {
      return;
    }
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.rejecting,
        clearMessage: true,
      ),
    );
    try {
      final request = ReviewMedicalDocumentRequest.reject(
        documentVersion: document.version,
        rejectionReasonCode: reasonCode,
        rejectionComment: comment,
      );
      final reviewed = await reviewUseCase(
        document.id,
        request,
        originalAnimalIds: document.animalIds,
      );
      await _applyTerminalOrReviewState(reviewed);
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _handleVersionConflict(document.id);
      } else {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            message: error.message,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message: _message(error),
        ),
      );
    }
  }

  Future<void> _acceptReplacement() async {
    final anchor = state.replacementAnchor;
    final candidate = state.remoteDocument;
    final extraction = state.draftExtraction;
    final finalCategory = state.selectedFinalCategory ?? anchor?.finalCategory;
    final reviewReplacement = reviewReplacementUseCase;
    if (anchor == null ||
        candidate == null ||
        extraction == null ||
        finalCategory == null ||
        reviewReplacement == null ||
        candidate.status != MedicalDocumentStatus.reviewPending) {
      return;
    }

    final relatedByAnimalId = <String, MedicalDocumentEntity>{};
    for (final document in state.relatedDocuments) {
      if (document.animalIds.length == 1) {
        relatedByAnimalId[document.animalIds.single] = document;
      }
    }
    final selectedDocuments = state.animalIds
        .map((animalId) => relatedByAnimalId[animalId])
        .whereType<MedicalDocumentEntity>()
        .toList(growable: false);
    if (state.animalIds.isEmpty ||
        selectedDocuments.length != state.animalIds.length) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message:
              'Actualiza los animales relacionados antes de confirmar la edición.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.submitting,
        clearMessage: true,
      ),
    );
    try {
      final request = ReviewMedicalDocumentReplacementRequest.accept(
        candidateDocumentId: candidate.id,
        documentVersion: anchor.version,
        candidateVersion: candidate.version,
        documentVersions: selectedDocuments
            .map(
              (document) => MedicalDocumentVersion(
                documentId: document.id,
                version: document.version,
              ),
            )
            .toList(growable: false),
        finalCategory: finalCategory,
        validatedExtraction: extraction,
        assignments: state.animalIds
            .map(
              (animalId) => MedicalDocumentAssignmentEntity(
                animalId: animalId,
                extractedItemIds:
                    state.assignmentsByAnimalId[animalId] ?? const [],
              ),
            )
            .toList(growable: false),
      );
      final updatedDocuments = await reviewReplacement(anchor.id, request);
      await pendingLocalDataSource.clear();
      if (isClosed) return;
      final mergedRelated = _mergeRelatedDocuments(
        state.relatedDocuments,
        updatedDocuments,
      );
      final updatedAnchor =
          _documentById(updatedDocuments, anchor.id) ?? anchor;
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.completed,
          remoteDocument:
              _documentById(updatedDocuments, anchor.id) ??
              updatedDocuments.firstOrNull ??
              anchor,
          replacementAnchor: updatedAnchor,
          relatedDocuments: mergedRelated,
          replacementResultDocuments: List.unmodifiable(updatedDocuments),
          clearMessage: true,
          versionConflict: false,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _refreshReplacementAfterConflict(
          candidateDocumentId: candidate.id,
          fallbackPhase: MedicalDocumentFlowPhase.reviewing,
        );
      } else {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            message: error.message,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message: _message(error),
        ),
      );
    }
  }

  Future<void> _rejectReplacement({bool showSubmittingState = true}) async {
    final anchor = state.replacementAnchor;
    final candidate = state.remoteDocument;
    final reviewReplacement = reviewReplacementUseCase;
    if (anchor == null ||
        candidate == null ||
        reviewReplacement == null ||
        candidate.status != MedicalDocumentStatus.reviewPending) {
      return;
    }

    if (showSubmittingState) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.rejecting,
          clearMessage: true,
        ),
      );
    }
    try {
      final documents = await reviewReplacement(
        anchor.id,
        ReviewMedicalDocumentReplacementRequest.reject(
          candidateDocumentId: candidate.id,
          documentVersion: anchor.version,
          candidateVersion: candidate.version,
        ),
      );
      await pendingLocalDataSource.clear();
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.rejected,
          relatedDocuments: _mergeRelatedDocuments(
            state.relatedDocuments,
            documents,
          ),
          replacementResultDocuments: List.unmodifiable(documents),
          clearMessage: true,
          versionConflict: false,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        await _refreshReplacementAfterConflict(
          candidateDocumentId: candidate.id,
          fallbackPhase: MedicalDocumentFlowPhase.reviewing,
        );
      } else {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            message: error.message,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.reviewing,
          message: _message(error),
        ),
      );
    }
  }

  List<String> _editableReplacementAnimalIds(
    MedicalDocumentEntity anchor,
    List<MedicalDocumentEntity> relatedDocuments,
  ) {
    final documents = <MedicalDocumentEntity>[
      ...relatedDocuments,
      if (!relatedDocuments.any((document) => document.id == anchor.id)) anchor,
    ];
    final seen = <String>{};
    return [
      for (final document in documents)
        if (document.canReplace && document.animalIds.length == 1)
          if (seen.add(document.animalIds.single)) document.animalIds.single,
    ];
  }

  List<MedicalDocumentEntity> _mergeRelatedDocuments(
    List<MedicalDocumentEntity> current,
    List<MedicalDocumentEntity> updated,
  ) {
    final updatedById = {for (final document in updated) document.id: document};
    final merged = <MedicalDocumentEntity>[
      for (final document in current)
        updatedById.remove(document.id) ?? document,
      ...updatedById.values,
    ];
    return List<MedicalDocumentEntity>.unmodifiable(merged);
  }

  MedicalDocumentEntity? _documentById(
    List<MedicalDocumentEntity> documents,
    String documentId,
  ) {
    for (final document in documents) {
      if (document.id == documentId) return document;
    }
    return null;
  }

  Future<void> _refreshReplacementAfterConflict({
    required String? candidateDocumentId,
    required MedicalDocumentFlowPhase fallbackPhase,
  }) async {
    final anchor = state.replacementAnchor;
    final getRelated = getRelatedDocumentsUseCase;
    if (anchor == null || getRelated == null) {
      emit(
        state.copyWith(
          phase: fallbackPhase,
          versionConflict: true,
          message:
              'El archivo cambió en el servidor. Actualiza los datos e inténtalo nuevamente.',
        ),
      );
      return;
    }

    try {
      final related = await getRelated(anchor.id);
      final refreshedAnchor = _documentById(related, anchor.id) ?? anchor;
      MedicalDocumentEntity? refreshedCandidate = state.remoteDocument;
      if (candidateDocumentId != null) {
        refreshedCandidate = await getDocumentUseCase(candidateDocumentId);
      }
      final editableIds = _editableReplacementAnimalIds(
        refreshedAnchor,
        related,
      ).toSet();
      final selectedAnimalIds = state.animalIds
          .where(editableIds.contains)
          .toList(growable: false);
      emit(
        state.copyWith(
          phase: fallbackPhase,
          animalIds: List.unmodifiable(selectedAnimalIds),
          remoteDocument: refreshedCandidate,
          replacementAnchor: refreshedAnchor,
          relatedDocuments: List.unmodifiable(related),
          assignmentsByAnimalId: {
            for (final animalId in selectedAnimalIds)
              animalId: state.assignmentsByAnimalId[animalId] ?? const [],
          },
          versionConflict: true,
          message:
              'El archivo cambió en el servidor. Revisa los animales y confirma nuevamente.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          phase: fallbackPhase,
          versionConflict: true,
          message: _message(error),
        ),
      );
    }
  }

  void pausePolling() {
    if (state.phase != MedicalDocumentFlowPhase.analyzing) return;
    _pollGeneration++;
    emit(state.copyWith(phase: MedicalDocumentFlowPhase.pollingPaused));
  }

  /// Discards the local flow and, for a replacement awaiting review, rejects
  /// its temporary candidate first so it cannot keep blocking the anchor.
  Future<bool> discardCurrentFlow({
    bool showSubmittingState = true,
    bool resetStateAfterDiscard = true,
  }) async {
    if (state.isReplacement) {
      var candidate = state.remoteDocument;
      if (candidate != null &&
          (candidate.status == MedicalDocumentStatus.pendingUpload ||
              candidate.status == MedicalDocumentStatus.analyzing)) {
        try {
          final activePolling = _pollCompletion;
          if (_polling && activePolling != null) {
            await activePolling;
          }
          if (isClosed) return false;
          candidate = state.remoteDocument ?? candidate;
          if (candidate.status == MedicalDocumentStatus.pendingUpload ||
              candidate.status == MedicalDocumentStatus.analyzing) {
            await _poll(candidate.id, pollImmediately: true);
            if (isClosed) return false;
            candidate = state.remoteDocument ?? candidate;
          }
          if (isClosed) return false;
        } catch (error) {
          if (!isClosed) {
            emit(
              state.copyWith(
                phase: MedicalDocumentFlowPhase.pollingPaused,
                message: _message(error),
              ),
            );
          }
          return false;
        }
      }

      if (candidate?.status == MedicalDocumentStatus.reviewPending) {
        await _rejectReplacement(showSubmittingState: showSubmittingState);
        if (isClosed || state.phase != MedicalDocumentFlowPhase.rejected) {
          return false;
        }
      } else if (candidate?.status == MedicalDocumentStatus.pendingUpload ||
          candidate?.status == MedicalDocumentStatus.analyzing) {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.pollingPaused,
            message:
                'El reemplazo todavía se está analizando. Espera a que termine para poder cancelar la edición.',
          ),
        );
        return false;
      }
    }

    _pollGeneration++;
    await pendingLocalDataSource.clear();
    if (resetStateAfterDiscard) {
      emit(const MedicalDocumentFlowState());
    }
    return true;
  }

  Future<void> reset() async {
    _pollGeneration++;
    await pendingLocalDataSource.clear();
    emit(const MedicalDocumentFlowState());
  }

  Future<void> resumePolling() async {
    final documentId =
        state.remoteDocument?.id ?? pendingLocalDataSource.read()?.documentId;
    if (documentId == null) return;
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.analyzing,
        clearMessage: true,
      ),
    );
    await _poll(documentId, pollImmediately: true);
  }

  String _message(Object error) {
    if (error is ApiException) {
      return switch (error.statusCode) {
        400 => 'El archivo o los datos enviados no son válidos.',
        401 => 'Tu sesión expiró. Inicia sesión nuevamente para continuar.',
        403 => 'No tienes acceso a uno o más animales seleccionados.',
        404 => 'El archivo o uno de los animales ya no existe.',
        413 => 'El archivo debe pesar máximo 10 MB.',
        502 =>
          'El servicio de análisis no está disponible. Inténtalo nuevamente.',
        _ => error.message,
      };
    }
    return error.toString().replaceFirst(
      RegExp(r'^(Exception|ApiException):\s*'),
      '',
    );
  }

  @override
  Future<void> close() {
    _pollGeneration++;
    return super.close();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
