import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/models/animal_transfer_recipient.dart';
import 'package:equatable/equatable.dart';

enum AnimalTransferStep { searchUser, confirmUser, verifyContact, completed }

class AnimalTransferState extends Equatable {
  final List<AnimalModel> animals;
  final String query;
  final List<AnimalTransferRecipient> results;
  final AnimalTransferRecipient? selectedRecipient;
  final AnimalTransferStep step;
  final List<String> transferReasons;
  final String identificationNumber;
  final String transferReason;
  final String otherReasonDetail;
  final String verificationIdentifier;

  const AnimalTransferState({
    required this.animals,
    this.query = '',
    this.results = const [],
    this.selectedRecipient,
    this.step = AnimalTransferStep.searchUser,
    this.transferReasons = const [],
    this.identificationNumber = '',
    this.transferReason = '',
    this.otherReasonDetail = '',
    this.verificationIdentifier = '',
  });

  bool get canContinue => animals.isNotEmpty && selectedRecipient != null;
  bool get requiresOtherReason => transferReason == 'Otro';

  /// Checks UI completeness only. Recipient identity must be verified by the
  /// future backend; a masked identification is not enough to verify it here.
  bool get canTransfer =>
      step == AnimalTransferStep.confirmUser &&
      canContinue &&
      RegExp(r'^[a-zA-Z0-9]{1,50}$').hasMatch(identificationNumber) &&
      transferReasons.contains(transferReason) &&
      (!requiresOtherReason || otherReasonDetail.trim().isNotEmpty) &&
      verificationIdentifier.trim().isNotEmpty;

  AnimalTransferState copyWith({
    AnimalTransferStep? step,
    String? identificationNumber,
    String? transferReason,
    String? otherReasonDetail,
  }) => AnimalTransferState(
    animals: animals,
    query: query,
    results: results,
    selectedRecipient: selectedRecipient,
    step: step ?? this.step,
    transferReasons: transferReasons,
    identificationNumber: identificationNumber ?? this.identificationNumber,
    transferReason: transferReason ?? this.transferReason,
    otherReasonDetail: otherReasonDetail ?? this.otherReasonDetail,
    verificationIdentifier: verificationIdentifier,
  );

  @override
  List<Object?> get props => [
    animals,
    query,
    results,
    selectedRecipient,
    step,
    transferReasons,
    identificationNumber,
    transferReason,
    otherReasonDetail,
    verificationIdentifier,
  ];
}
