import 'package:equatable/equatable.dart';

class ChangePinParams extends Equatable {
  final String oldPin;
  final String newPin;

  const ChangePinParams({required this.oldPin, required this.newPin});

  @override
  List<Object?> get props => [oldPin, newPin];
}
