import 'package:animal_record/features/auth/domain/entities/register_params.dart';
import 'package:animal_record/features/auth/domain/entities/login_params.dart';
import 'package:animal_record/features/auth/domain/entities/verify_code_params.dart';
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

// Este evento se dispara cuando el usuario presiona "Verificar"
class VerifyCodeSubmitted extends AuthEvent {
  final VerifyCodeParams params;
  VerifyCodeSubmitted(this.params);

  @override
  List<Object?> get props => [params];
}

// Este evento se dispara cuando el usuario solicita reenviar el código
class ResendCodeSubmitted extends AuthEvent {
  final String identifier; // Email or phone number
  ResendCodeSubmitted(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

// Este evento se dispara para verificar si un número de identificación ya existe
class CheckIdentificationExists extends AuthEvent {
  final String identificationNumber;
  CheckIdentificationExists(this.identificationNumber);

  @override
  List<Object?> get props => [identificationNumber];
}

class SocialAuthChecked extends AuthEvent {
  final String provider;
  final String token;

  SocialAuthChecked({required this.provider, required this.token});

  @override
  List<Object?> get props => [provider, token];
}

class SocialRegisterSubmitted extends AuthEvent {
  final Map<String, dynamic> data;

  SocialRegisterSubmitted(this.data);

  @override
  List<Object?> get props => [data];
}

class FetchUserRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String userId;
  final Map<String, dynamic> data;

  UpdateProfileRequested({required this.userId, required this.data});

  @override
  List<Object?> get props => [userId, data];
}
