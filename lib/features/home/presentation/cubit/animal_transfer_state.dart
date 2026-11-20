import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';
import 'package:equatable/equatable.dart';
import 'package:animal_record/features/home/domain/services/transfer_comment_policy.dart';

enum AnimalTransferStep { searchUser, confirmUser, verifyContact, completed }

class AnimalTransferState extends Equatable {
  final List<AnimalModel> animals;
  final String query;
  final List<AnimalTransferRecipient> results;
  final String? nextRecipientCursor;
  final AnimalTransferRecipient? selectedRecipient;
  final AnimalTransferStep step;
  final List<TransferReason> transferReasons;
  final bool isLoadingReasons;
  final String identificationNumber;
  final String transferReasonCode;
  final String otherReasonDetail;
  final TransferChallenge? challenge;
  final TransferRequest? request;
  final bool isLoading;
  final String? error;
  final bool canRetryCreation;
  final DateTime? authorizationExpiresAt;

  const AnimalTransferState({
    required this.animals,
    this.query = '',
    this.results = const [],
    this.nextRecipientCursor,
    this.selectedRecipient,
    this.step = AnimalTransferStep.searchUser,
    this.transferReasons = const [],
    this.isLoadingReasons = false,
    this.identificationNumber = '',
    this.transferReasonCode = '',
    this.otherReasonDetail = '',
    this.challenge,
    this.request,
    this.isLoading = false,
    this.error,
    this.canRetryCreation = false,
    this.authorizationExpiresAt,
  });

  bool get canContinue => animals.isNotEmpty && selectedRecipient != null;
  bool get requiresOtherReason =>
      transferReasonCode == 'OTHER' ||
      transferReasons.any(
        (reason) => reason.code == transferReasonCode && reason.needsComment,
      );

  bool get canTransfer =>
      step == AnimalTransferStep.confirmUser &&
      canContinue &&
      !isLoading &&
      identificationNumber == selectedRecipient!.identificationNumber &&
      transferReasons.any((reason) => reason.code == transferReasonCode) &&
      (!requiresOtherReason ||
          TransferCommentPolicy.isValid(otherReasonDetail));

  AnimalTransferState copyWith({
    AnimalTransferStep? step,
    List<AnimalTransferRecipient>? results,
    String? nextRecipientCursor,
    bool clearRecipientCursor = false,
    List<TransferReason>? transferReasons,
    bool? isLoadingReasons,
    String? identificationNumber,
    String? transferReasonCode,
    String? otherReasonDetail,
    TransferChallenge? challenge,
    TransferRequest? request,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? canRetryCreation,
    DateTime? authorizationExpiresAt,
  }) => AnimalTransferState(
    animals: animals,
    query: query,
    results: results ?? this.results,
    nextRecipientCursor: clearRecipientCursor
        ? null
        : nextRecipientCursor ?? this.nextRecipientCursor,
    selectedRecipient: selectedRecipient,
    step: step ?? this.step,
    transferReasons: transferReasons ?? this.transferReasons,
    isLoadingReasons: isLoadingReasons ?? this.isLoadingReasons,
    identificationNumber: identificationNumber ?? this.identificationNumber,
    transferReasonCode: transferReasonCode ?? this.transferReasonCode,
    otherReasonDetail: otherReasonDetail ?? this.otherReasonDetail,
    challenge: challenge ?? this.challenge,
    request: request ?? this.request,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    canRetryCreation: canRetryCreation ?? this.canRetryCreation,
    authorizationExpiresAt:
        authorizationExpiresAt ?? this.authorizationExpiresAt,
  );

  @override
  List<Object?> get props => [
    animals,
    query,
    results,
    nextRecipientCursor,
    selectedRecipient,
    step,
    transferReasons,
    isLoadingReasons,
    identificationNumber,
    transferReasonCode,
    otherReasonDetail,
    challenge,
    request,
    isLoading,
    error,
    canRetryCreation,
    authorizationExpiresAt,
  ];
}
