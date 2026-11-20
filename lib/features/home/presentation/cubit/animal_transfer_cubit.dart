import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/network/transfer_error_diagnostics.dart';
import 'package:animal_record/features/home/presentation/utils/transfer_error_feedback.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/transfer_otp_policy.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class AnimalTransferCubit extends Cubit<AnimalTransferState> {
  final AnimalTransferRepository repository;
  int _searchGeneration = 0;
  String? _pendingKey;
  Map<String, Object>? _pendingBody;
  DateTime? _otpRetryAt;
  Future<void>? _reasonsLoad;

  bool get hasPendingIntent => _pendingKey != null;
  // A pending operation must always retain its original authorization payload.
  bool get canRenewAuthorization => false;

  AnimalTransferCubit({
    required List<AnimalModel> animals,
    required this.repository,
  }) : super(
         AnimalTransferState(
           animals: List.unmodifiable(
             {
               for (final animal in animals)
                 if (animal.canTransfer) animal.id: animal,
             }.values,
           ),
         ),
       );

  Future<void> loadReasons() async {
    if (isClosed) return;
    final pending = _reasonsLoad;
    if (pending != null) return pending;
    final request = _loadReasons();
    _reasonsLoad = request;
    try {
      await request;
    } finally {
      if (identical(_reasonsLoad, request)) _reasonsLoad = null;
    }
  }

  Future<void> _loadReasons() async {
    emit(state.copyWith(isLoadingReasons: true));
    try {
      final reasons = await repository.getReasons();
      if (reasons.isEmpty) {
        throw const FormatException(
          'El servidor no tiene motivos de transferencia disponibles. El administrador debe revisar el catálogo.',
        );
      }
      if (!isClosed) {
        emit(state.copyWith(transferReasons: reasons, isLoadingReasons: false));
      }
    } catch (error) {
      TransferErrorDiagnostics.record(error);
      if (!isClosed) {
        emit(state.copyWith(isLoadingReasons: false));
      }
    }
  }

  Future<void> search(String query) async {
    if (hasPendingIntent || state.step != AnimalTransferStep.searchUser) return;
    final generation = ++_searchGeneration;
    final name = query.trim();
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: query,
        transferReasons: state.transferReasons,
        isLoadingReasons: state.isLoadingReasons,
        isLoading: name.length >= 2,
      ),
    );
    if (name.length < 2) return;
    if (name.length > 100) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'La búsqueda admite hasta 100 caracteres.',
        ),
      );
      return;
    }
    try {
      final page = await repository.searchRecipients(name);
      if (isClosed || generation != _searchGeneration) return;
      emit(
        state.copyWith(
          results: page.items,
          nextRecipientCursor: page.nextCursor,
          clearRecipientCursor: page.nextCursor == null,
          isLoading: false,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _searchGeneration) return;
      emit(state.copyWith(isLoading: false, error: _message(error)));
    }
  }

  Future<void> loadMoreRecipients() async {
    final cursor = state.nextRecipientCursor;
    if (cursor == null || state.isLoading) return;
    final generation = _searchGeneration;
    final before = state;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final page = await repository.searchRecipients(
        before.query.trim(),
        cursor: cursor,
      );
      if (isClosed || generation != _searchGeneration) return;
      emit(
        state.copyWith(
          results: [...before.results, ...page.items],
          nextRecipientCursor: page.nextCursor,
          clearRecipientCursor: page.nextCursor == null,
          isLoading: false,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _searchGeneration) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: _message(error),
          nextRecipientCursor: cursor,
        ),
      );
    }
  }

  void selectRecipient(AnimalTransferRecipient recipient) {
    if (hasPendingIntent || state.isLoading) return;
    if (!state.results.contains(recipient)) return;
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: state.query,
        results: state.results,
        selectedRecipient: recipient,
        nextRecipientCursor: state.nextRecipientCursor,
        transferReasons: state.transferReasons,
        isLoadingReasons: state.isLoadingReasons,
      ),
    );
  }

  void confirmRecipient() {
    if (state.canContinue && !hasPendingIntent && !state.isLoading) {
      emit(state.copyWith(step: AnimalTransferStep.confirmUser));
      if (state.transferReasons.isEmpty) unawaited(loadReasons());
    }
  }

  void backToSearch() {
    if (hasPendingIntent || state.isLoading) return;
    ++_searchGeneration;
    emit(state.copyWith(step: AnimalTransferStep.searchUser));
  }

  void updateIdentificationNumber(String value) {
    if (state.step == AnimalTransferStep.confirmUser) {
      emit(state.copyWith(identificationNumber: value, clearError: true));
    }
  }

  void selectTransferReason(String? code) {
    if (state.step != AnimalTransferStep.confirmUser) return;
    if (code != null && !state.transferReasons.any((r) => r.code == code)) {
      return;
    }
    emit(
      state.copyWith(
        transferReasonCode: code ?? '',
        otherReasonDetail: code == state.transferReasonCode ? null : '',
        clearError: true,
      ),
    );
  }

  void updateOtherReasonDetail(String value) {
    if (state.step == AnimalTransferStep.confirmUser &&
        state.requiresOtherReason) {
      emit(state.copyWith(otherReasonDetail: value, clearError: true));
    }
  }

  Future<void> startVerification() async {
    if (!state.canTransfer || hasPendingIntent || _otpThrottled) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final challenge = await repository.startChallenge();
      if (!isClosed) {
        emit(
          state.copyWith(
            step: AnimalTransferStep.verifyContact,
            challenge: challenge,
            isLoading: false,
          ),
        );
      }
    } catch (error) {
      TransferErrorDiagnostics.recordOtpChallengeFailure(error);
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: _message(error)));
      }
    }
  }

  void backToConfirmation() {
    if (state.step == AnimalTransferStep.verifyContact &&
        !state.isLoading &&
        !hasPendingIntent &&
        !state.canRetryCreation) {
      emit(
        state.copyWith(step: AnimalTransferStep.confirmUser, clearError: true),
      );
    }
  }

  Future<void> resendCode() async {
    final challenge = state.challenge;
    if (challenge == null ||
        state.isLoading ||
        hasPendingIntent ||
        _otpThrottled ||
        DateTime.now().isBefore(challenge.resendAvailableAt)) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final updated = await repository.resendChallenge(challenge.id);
      if (!isClosed) emit(state.copyWith(challenge: updated, isLoading: false));
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: _message(error)));
      }
    }
  }

  Future<void> verifyAndCreate(String code) async {
    final challenge = state.challenge;
    if (state.step != AnimalTransferStep.verifyContact ||
        challenge == null ||
        state.isLoading ||
        !TransferOtpPolicy.isValid(code)) {
      return;
    }
    // Never replace the authorization/body of an operation with an uncertain result.
    if (hasPendingIntent) {
      await retryCreation();
      return;
    }
    if (_otpThrottled || !DateTime.now().isBefore(challenge.expiresAt)) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final authorization = await repository.verifyChallenge(
        challenge.id,
        code,
      );
      if (isClosed) return;
      _pendingKey = const Uuid().v4();
      _pendingBody = Map.unmodifiable(<String, Object>{
        'recipientId': state.selectedRecipient!.id,
        'reasonCode': state.transferReasonCode,
        if (state.requiresOtherReason)
          'reasonComment': state.otherReasonDetail.trim(),
        'animalIds': List<String>.unmodifiable(
          state.animals.map((animal) => animal.id),
        ),
        'authorization': Map<String, String>.unmodifiable({
          'challengeId': challenge.id,
          'proof': authorization.proof,
        }),
      });
      emit(state.copyWith(authorizationExpiresAt: authorization.expiresAt));
      await _submitPending();
    } catch (error) {
      TransferErrorDiagnostics.record(error);
      if (!isClosed) {
        final proofUncertain =
            error is ApiException &&
            (error.statusCode == null || (error.statusCode ?? 0) >= 500);
        emit(
          state.copyWith(
            isLoading: false,
            step: proofUncertain && !hasPendingIntent
                ? AnimalTransferStep.confirmUser
                : AnimalTransferStep.verifyContact,
            canRetryCreation: proofUncertain && hasPendingIntent,
            error: proofUncertain
                ? 'No se pudo confirmar el código. Solicita un desafío nuevo cuando esté disponible.'
                : _message(error),
          ),
        );
      }
    }
  }

  Future<void> retryCreation() async {
    if (!state.canRetryCreation || state.isLoading) return;
    // An idempotent replay may recover an already-created request after proof expiry.
    emit(state.copyWith(isLoading: true, clearError: true));
    await _submitPending();
  }

  bool get _authorizationExpired {
    final expiresAt = state.authorizationExpiresAt;
    return expiresAt != null && !DateTime.now().isBefore(expiresAt);
  }

  Future<void> renewAuthorization() async {
    // Keep the existing presentation callback safe for uncertain operations.
    await retryCreation();
  }

  Future<void> _submitPending() async {
    final key = _pendingKey;
    final body = _pendingBody;
    if (key == null || body == null) return;
    try {
      final request = await repository.createTransfer(
        idempotencyKey: key,
        body: body,
      );
      _pendingBody = null;
      _pendingKey = null;
      if (!isClosed) {
        emit(
          state.copyWith(
            request: request,
            step: AnimalTransferStep.completed,
            isLoading: false,
            canRetryCreation: false,
          ),
        );
      }
    } catch (error) {
      if (isClosed) return;
      TransferErrorDiagnostics.record(error);
      final uncertain =
          error is! ApiException ||
          error.statusCode == null ||
          error.statusCode == 408 ||
          (error.statusCode ?? 0) >= 500 ||
          (error.statusCode ?? 0) < 300;
      final authorizationExpired =
          error is ApiException &&
          error.statusCode == 400 &&
          _authorizationExpired;
      if (!uncertain) {
        _pendingBody = null;
        _pendingKey = null;
      }
      emit(
        state.copyWith(
          isLoading: false,
          canRetryCreation: uncertain,
          step: uncertain
              ? AnimalTransferStep.verifyContact
              : AnimalTransferStep.confirmUser,
          error: authorizationExpired
              ? 'La autorización venció. Solicita un código nuevo.'
              : uncertain
              ? 'Aún no pudimos confirmar tu solicitud. Revisa tus solicitudes antes de reintentar.'
              : _message(error),
        ),
      );
    }
  }

  bool get _otpThrottled =>
      _otpRetryAt != null && DateTime.now().isBefore(_otpRetryAt!);

  String _message(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 429 && error.retryAfter != null) {
        _otpRetryAt = error.retryAfterDeadline;
        final remaining = _otpRetryAt?.difference(DateTime.now()).inSeconds;
        return remaining != null && remaining >= 0
            ? '${TransferErrorFeedback.message(error)} Espera ${remaining + 1} segundos.'
            : TransferErrorFeedback.message(error);
      }
    }
    return TransferErrorFeedback.message(error);
  }

  @override
  Future<void> close() {
    _pendingBody = null;
    _pendingKey = null;
    return super.close();
  }
}
