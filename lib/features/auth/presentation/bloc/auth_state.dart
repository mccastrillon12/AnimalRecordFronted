import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {} // Para mostrar el círculo de carga

class AuthSuccess extends AuthState {
  final UserEntity user;
  final bool isUpdating;
  final String? updateError;
  final bool pinSaveSuccess;
  final bool pinVerifiedSuccess; // Added
  final bool pinChangeSuccess; // Added

  AuthSuccess(
    this.user, {
    this.isUpdating = false,
    this.updateError,
    this.pinSaveSuccess = false,
    this.pinVerifiedSuccess = false, // Added
    this.pinChangeSuccess = false, // Added
  });

  @override
  List<Object?> get props => [
    user,
    isUpdating,
    updateError,
    pinSaveSuccess,
    pinVerifiedSuccess,
    pinChangeSuccess,
  ];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class VerificationSuccess extends AuthState {}

class ResendCodeSuccess extends AuthState {}

class IdentificationCheckResult extends AuthState {
  final bool exists;
  IdentificationCheckResult(this.exists);

  @override
  List<Object?> get props => [exists];
}

class AuthUserNotVerified extends AuthState {
  final int? timeRemaining;
  AuthUserNotVerified({this.timeRemaining});

  @override
  List<Object?> get props => [timeRemaining];
}

class SocialAuthNeedRegister extends AuthState {
  final Map<String, dynamic> response;
  final String provider;

  SocialAuthNeedRegister(this.response, {this.provider = 'Google'});

  @override
  List<Object?> get props => [response, provider];
}

class PasswordChangeSuccess extends AuthSuccess {
  PasswordChangeSuccess(super.user);
}
