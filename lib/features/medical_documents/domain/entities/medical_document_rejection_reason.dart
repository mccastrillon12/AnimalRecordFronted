import 'package:equatable/equatable.dart';

class MedicalDocumentRejectionReasonEntity extends Equatable {
  final String code;
  final String label;
  final bool requiresComment;

  const MedicalDocumentRejectionReasonEntity({
    required this.code,
    required this.label,
    required this.requiresComment,
  });

  @override
  List<Object?> get props => [code, label, requiresComment];
}

class MedicalDocumentRejectionSelection extends Equatable {
  final MedicalDocumentRejectionReasonEntity reason;
  final String? comment;

  const MedicalDocumentRejectionSelection({required this.reason, this.comment});

  @override
  List<Object?> get props => [reason, comment];
}
