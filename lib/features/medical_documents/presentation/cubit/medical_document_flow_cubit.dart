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
  final GetMedicalDocumentUseCase getDocumentUseCase;
  final ReviewMedicalDocumentUseCase reviewUseCase;
  final PendingMedicalDocumentLocalDataSource pendingLocalDataSource;
  final MedicalDocumentPollDelay pollDelay;
  final MedicalDocumentItemIdGenerator itemIdGenerator;

  int _pollGeneration = 0;
  bool _polling = false;
  Future<void>? _pollCompletion;

  PendingMedicalDocumentFlow? get pendingFlow => pendingLocalDataSource.read();

  MedicalDocumentFlowCubit({
    required this.analyzeUseCase,
    required this.getDocumentUseCase,
    required this.reviewUseCase,
    required this.pendingLocalDataSource,
    MedicalDocumentPollDelay? pollDelay,
    MedicalDocumentItemIdGenerator? itemIdGenerator,
  }) : pollDelay = pollDelay ?? Future<void>.delayed,
       itemIdGenerator = itemIdGenerator ?? const Uuid().v4,
       super(const MedicalDocumentFlowState());

  Future<void> startAnalysis({
    required SharedFileEntity file,
    required List<String> animalIds,
    MedicalDocumentCategory? requestedCategory,
  }) async {
    _pollGeneration++;
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
        ),
      );
      await pendingLocalDataSource.save(
        PendingMedicalDocumentFlow(
          documentId: document.id,
          animalIds: animalIds,
          startedAt: DateTime.now(),
          requestedCategory: requestedCategory,
        ),
      );
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.analyzing,
          remoteDocument: document,
          clearMessage: true,
        ),
      );
      await _poll(document.id);
    } catch (error) {
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
        final category = _suggestedCategory(document);
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
    _emitReview(document, category);
  }

  void _emitReview(
    MedicalDocumentEntity document,
    MedicalDocumentCategory category,
  ) {
    final sanitized = _reviewExtraction(document, category);
    emit(
      state.copyWith(
        phase: MedicalDocumentFlowPhase.reviewing,
        remoteDocument: document,
        selectedFinalCategory: category,
        draftExtraction: sanitized,
        assignmentsByAnimalId: {
          for (final animalId in document.animalIds)
            animalId: List.unmodifiable(sanitized.extractedItemIds),
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
    final matchingExtraction = document.extractionsByCategory[category];
    if (matchingExtraction != null &&
        _hasExtractionContent(matchingExtraction)) {
      return matchingExtraction.sanitizedFor(category);
    }

    // A manually selected category has no inferred structure. The backend
    // contract requires a clean, category-specific draft instead of reusing
    // fields detected for a different category.
    return MedicalDocumentExtractionEntity.empty(category);
  }

  bool _hasExtractionContent(MedicalDocumentExtractionEntity extraction) {
    return _hasPreservedValue(extraction.summary) ||
        _hasPreservedValue(extraction.documentDate) ||
        _hasPreservedValue(extraction.issuer) ||
        (extraction.patient?.hasData ?? false) ||
        (extraction.owner?.hasData ?? false) ||
        extraction.patientHints.isNotEmpty ||
        extraction.diagnoses.isNotEmpty ||
        extraction.medications.isNotEmpty ||
        extraction.vaccinations.isNotEmpty ||
        extraction.medicalOrders.isNotEmpty ||
        _hasPreservedValue(extraction.clinicalHistory) ||
        extraction.diagnosticResults.isNotEmpty ||
        _hasPreservedValue(extraction.referral) ||
        extraction.diagnosticImages.isNotEmpty ||
        _hasPreservedValue(extraction.laboratoryReport) ||
        extraction.laboratoryResults.isNotEmpty ||
        extraction.additionalFields.isNotEmpty ||
        extraction.warnings.isNotEmpty;
  }

  bool _hasPreservedValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  void updateDraft(MedicalDocumentExtractionEntity extraction) {
    final category = state.selectedFinalCategory;
    if (category == null) return;
    final sanitized = extraction.sanitizedFor(category);
    final validIds = sanitized.extractedItemIds.toSet();
    emit(
      state.copyWith(
        draftExtraction: sanitized,
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
        validatedExtraction: extraction.sanitizedFor(category),
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
    final document = state.remoteDocument;
    if (document == null ||
        document.status != MedicalDocumentStatus.reviewPending) {
      return;
    }
    emit(state.copyWith(phase: MedicalDocumentFlowPhase.submitting));
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

  void pausePolling() {
    if (state.phase != MedicalDocumentFlowPhase.analyzing) return;
    _pollGeneration++;
    emit(state.copyWith(phase: MedicalDocumentFlowPhase.pollingPaused));
  }

  /// Removes a flow from this device without turning a close/cancel action into
  /// a backend rejection. Rejection is only sent by [reject] with a reason.
  Future<bool> discardCurrentFlow({
    bool showSubmittingState = true,
    bool resetStateAfterDiscard = true,
  }) async {
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
