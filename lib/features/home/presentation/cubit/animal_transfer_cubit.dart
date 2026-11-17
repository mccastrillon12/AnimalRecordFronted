import 'package:animal_record/core/network/api_exception.dart';
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

  bool get hasPendingIntent => _pendingKey != null;
  bool get canRenewAuthorization =>
      hasPendingIntent &&
      state.canRetryCreation &&
      (state.authorizationExpiresAt == null || _authorizationExpired);

  AnimalTransferCubit({
    required List<AnimalModel> animals,
    required this.repository,
  }) : super(
         AnimalTransferState(
           animals: List.unmodifiable(
             {
               for (final animal in animals)
                 if (animal.isActive) animal.id: animal,
             }.values,
           ),
         ),
       );

  Future<void> loadReasons() async {
    try {
      final reasons = await repository.getReasons();
      if (!isClosed) emit(state.copyWith(transferReasons: reasons));
    } catch (error) {
      if (!isClosed) emit(state.copyWith(error: _message(error)));
    }
  }

  Future<void> search(String query) async {
    final generation = ++_searchGeneration;
    final name = query.trim();
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: query,
        transferReasons: state.transferReasons,
        isLoading: name.length >= 2,
      ),
    );
    if (name.length < 2) return;
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
    if (!state.results.contains(recipient)) return;
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: state.query,
        results: state.results,
        selectedRecipient: recipient,
        nextRecipientCursor: state.nextRecipientCursor,
        transferReasons: state.transferReasons,
      ),
    );
  }

  void confirmRecipient() {
    if (state.canContinue) {
      emit(state.copyWith(step: AnimalTransferStep.confirmUser));
    }
  }

  void backToSearch() =>
      emit(state.copyWith(step: AnimalTransferStep.searchUser));

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
    emit(state.copyWith(transferReasonCode: code ?? '', clearError: true));
  }

  Future<void> startVerification() async {
    if (!state.canTransfer) return;
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
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final authorization = await repository.verifyChallenge(
        challenge.id,
        code,
      );
      if (isClosed) return;
      _pendingKey ??= const Uuid().v4();
      _pendingBody = <String, Object>{
        if (_pendingBody == null) ...{
          'recipientId': state.selectedRecipient!.id,
          'reasonCode': state.transferReasonCode,
          'animalIds': state.animals
              .map((animal) => animal.id)
              .toList(growable: false),
        } else
          ..._pendingBody!,
        'authorization': <String, String>{
          'challengeId': challenge.id,
          'proof': authorization.proof,
        },
      };
      emit(state.copyWith(authorizationExpiresAt: authorization.expiresAt));
      await _submitPending();
    } catch (error) {
      if (!isClosed) {
        final proofUncertain =
            error is ApiException &&
            (error.statusCode == null || error.statusCode == 500);
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
    if (_authorizationExpired) {
      emit(
        state.copyWith(
          error:
              'La autorización venció. Solicita un código nuevo para esta misma solicitud.',
        ),
      );
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    await _submitPending();
  }

  bool get _authorizationExpired {
    final expiresAt = state.authorizationExpiresAt;
    return expiresAt != null && !DateTime.now().isBefore(expiresAt);
  }

  Future<void> renewAuthorization() async {
    if (!canRenewAuthorization || state.isLoading) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final challenge = await repository.startChallenge();
      if (!isClosed) {
        emit(
          state.copyWith(
            challenge: challenge,
            canRetryCreation: false,
            isLoading: false,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: _message(error)));
      }
    }
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
      final uncertain =
          error is ApiException &&
          (error.statusCode == null || error.statusCode == 503);
      final authorizationExpired =
          error is ApiException &&
          error.statusCode == 400 &&
          _authorizationExpired;
      if (!uncertain && !authorizationExpired) {
        _pendingBody = null;
        _pendingKey = null;
      }
      emit(
        state.copyWith(
          isLoading: false,
          canRetryCreation: uncertain || authorizationExpired,
          step: uncertain || authorizationExpired
              ? AnimalTransferStep.verifyContact
              : AnimalTransferStep.confirmUser,
          error: authorizationExpired
              ? 'La autorización venció. Solicita un código nuevo para la misma solicitud.'
              : uncertain
              ? 'Resultado incierto. Consulta tus solicitudes o reintenta con la misma operación.'
              : _message(error),
        ),
      );
    }
  }

  static String _message(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 429 && error.retryAfter != null) {
        return '${error.message} Espera ${error.retryAfter} segundos.';
      }
      return error.message;
    }
    return 'No se pudo completar la operación.';
  }

  @override
  Future<void> close() {
    _pendingBody = null;
    _pendingKey = null;
    return super.close();
  }
}
