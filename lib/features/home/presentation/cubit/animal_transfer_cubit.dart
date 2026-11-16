import 'package:animal_record/features/home/presentation/cubit/animal_transfer_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/models/animal_transfer_recipient.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Local presentation state only: never changes ownership or calls a service.
class AnimalTransferCubit extends Cubit<AnimalTransferState> {
  final List<AnimalTransferRecipient> _recipients;

  AnimalTransferCubit({
    required List<AnimalModel> animals,
    List<AnimalTransferRecipient> recipients = const [],
    List<String> transferReasons = const [],
    String verificationIdentifier = '',
  }) : _recipients = List.unmodifiable(recipients),
       super(
         AnimalTransferState(
           transferReasons: List.unmodifiable(transferReasons),
           verificationIdentifier: verificationIdentifier,
           animals: List.unmodifiable(
             {
               for (final animal in animals)
                 if (animal.isActive) animal.id: animal,
             }.values,
           ),
         ),
       );

  void search(String query) {
    final normalized = _normalize(query.trim());
    final results = normalized.isEmpty
        ? <AnimalTransferRecipient>[]
        : _recipients
              .where((recipient) {
                return _normalize(recipient.name).contains(normalized) ||
                    recipient.maskedIdentification.contains(normalized);
              })
              .toList(growable: false);
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: query,
        results: List.unmodifiable(results),
        transferReasons: state.transferReasons,
        verificationIdentifier: state.verificationIdentifier,
      ),
    );
  }

  void selectRecipient(AnimalTransferRecipient recipient) {
    if (!state.results.contains(recipient)) return;
    if (state.selectedRecipient == recipient) return;
    emit(
      AnimalTransferState(
        animals: state.animals,
        query: state.query,
        results: state.results,
        selectedRecipient: recipient,
        transferReasons: state.transferReasons,
        verificationIdentifier: state.verificationIdentifier,
      ),
    );
  }

  void confirmRecipient() {
    if (!state.canContinue) return;
    emit(state.copyWith(step: AnimalTransferStep.confirmUser));
  }

  void backToSearch() {
    emit(state.copyWith(step: AnimalTransferStep.searchUser));
  }

  void updateIdentificationNumber(String value) {
    if (state.step != AnimalTransferStep.confirmUser) return;
    emit(state.copyWith(identificationNumber: value));
  }

  void selectTransferReason(String? reason) {
    if (state.step != AnimalTransferStep.confirmUser) return;
    if (reason != null && !state.transferReasons.contains(reason)) return;
    emit(
      state.copyWith(
        transferReason: reason ?? '',
        otherReasonDetail: reason == state.transferReason
            ? state.otherReasonDetail
            : '',
      ),
    );
  }

  void updateOtherReasonDetail(String value) {
    if (state.step != AnimalTransferStep.confirmUser ||
        !state.requiresOtherReason) {
      return;
    }
    emit(state.copyWith(otherReasonDetail: value));
  }

  void startVerification() {
    if (!state.canTransfer) return;
    emit(state.copyWith(step: AnimalTransferStep.verifyContact));
  }

  void backToConfirmation() {
    if (state.step != AnimalTransferStep.verifyContact) return;
    emit(state.copyWith(step: AnimalTransferStep.confirmUser));
  }

  /// Completes only the visual demo. Replace with the server-confirmed outcome
  /// when the OTP and transfer contracts are available. Never stores the code.
  void completePreview(String code) {
    if (state.step != AnimalTransferStep.verifyContact ||
        !RegExp(r'^[a-zA-Z0-9]{5}$').hasMatch(code)) {
      return;
    }
    emit(state.copyWith(step: AnimalTransferStep.completed));
  }

  static String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    for (final entry in accents.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
