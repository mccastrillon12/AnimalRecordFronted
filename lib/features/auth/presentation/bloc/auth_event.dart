import 'package:animal_record/features/auth/domain/entities/register_params.dart';
import 'package:animal_record/features/auth/domain/entities/login_params.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Este evento se dispara cuando el usuario presiona "Registrar"
class SignUpSubmitted extends AuthEvent {
  final RegisterParams userData;
  SignUpSubmitted(this.userData);

  @override
  List<Object?> get props => [userData];
}

// Este evento se dispara cuando el usuario presiona "Ingresar"
class LoginSubmitted extends AuthEvent {
  final LoginParams credentials;
  LoginSubmitted(this.credentials);

  @override
  List<Object?> get props => [credentials];
}
