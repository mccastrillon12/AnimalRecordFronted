import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Este evento se dispara cuando el usuario presiona "Registrar"
class SignUpSubmitted extends AuthEvent {
  final Map<String, dynamic> userData;
  SignUpSubmitted(this.userData);

  @override
  List<Object?> get props => [userData];
}
