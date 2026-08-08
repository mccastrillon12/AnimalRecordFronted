import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/medical_documents/data/datasources/pending_medical_document_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_flow_state.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef MedicalDocumentPollDelay = Future<void> Function(Duration duration);

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
  }) : pollDelay = pollDelay ?? Future<void>.delayed,
       super(const MedicalDocumentFlowState());

  Future<void> startAnalysis({
    required SharedFileEntity file,
    required List<String> animalIds,
    MedicalDocumentCategory? requestedCategory,
  }) async {
    if (animalIds.isEmpty) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.failed,
          message: 'Selecciona al menos un animal.',
        ),
      );
      return;
    }
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
        await pendingLocalDataSource.clear();
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.failed,
            remoteDocument: document,
            message: 'No fue posible analizar el documento.',
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
            document.requestedCategory ??
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
    final extraction =
        document.extractionsByCategory[category] ??
        MedicalDocumentExtractionEntity.empty(category);
    final sanitized = extraction.sanitizedFor(category);
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
      final reviewed = await reviewUseCase(
        document.id,
        ReviewMedicalDocumentRequest.accept(
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
        ),
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
                'El documento cambió en el servidor. Revisa los datos y confirma nuevamente.',
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

  Future<void> reject() async {
    final document = state.remoteDocument;
    if (document == null ||
        document.status != MedicalDocumentStatus.reviewPending) {
      return;
    }
    emit(state.copyWith(phase: MedicalDocumentFlowPhase.submitting));
    try {
      final reviewed = await reviewUseCase(
        document.id,
        ReviewMedicalDocumentRequest.reject(documentVersion: document.version),
      );
      await _applyTerminalOrReviewState(reviewed);
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

  /// Discards a user-cancelled flow before another document can be analyzed.
  /// A document awaiting review is rejected remotely; earlier phases are only
  /// removed locally because the API does not expose an analysis-cancel action.
  Future<bool> discardCurrentFlow() async {
    _pollGeneration++;
    final document = state.remoteDocument;
    if (document?.status == MedicalDocumentStatus.reviewPending) {
      emit(
        state.copyWith(
          phase: MedicalDocumentFlowPhase.submitting,
          clearMessage: true,
        ),
      );
      try {
        await reviewUseCase(
          document!.id,
          ReviewMedicalDocumentRequest.reject(
            documentVersion: document.version,
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            phase: MedicalDocumentFlowPhase.reviewing,
            message: _message(error),
          ),
        );
        return false;
      }
    }
    await pendingLocalDataSource.clear();
    emit(const MedicalDocumentFlowState());
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
        404 => 'El documento o uno de los animales ya no existe.',
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
