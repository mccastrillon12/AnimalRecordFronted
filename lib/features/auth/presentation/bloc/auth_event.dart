import 'package:animal_record/features/auth/domain/entities/register_params.dart';
import 'package:animal_record/features/auth/domain/entities/login_params.dart';
import 'package:animal_record/features/auth/domain/entities/verify_code_params.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignUpSubmitted extends AuthEvent {
  final RegisterParams userData;
  SignUpSubmitted(this.userData);

  @override
  List<Object?> get props => [userData];
}

class LoginSubmitted extends AuthEvent {
  final LoginParams credentials;
  LoginSubmitted(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class VerifyCodeSubmitted extends AuthEvent {
  final VerifyCodeParams params;
  VerifyCodeSubmitted(this.params);

  @override
  List<Object?> get props => [params];
}

class ResendCodeSubmitted extends AuthEvent {
  final String identifier;
  ResendCodeSubmitted(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class CheckIdentificationExists extends AuthEvent {
  final String identificationNumber;
  CheckIdentificationExists(this.identificationNumber);

  @override
  List<Object?> get props => [identificationNumber];
}

class SocialAuthChecked extends AuthEvent {
  final String provider;
  final String token;
  final String? firstName;
  final String? lastName;

  SocialAuthChecked({
    required this.provider,
    required this.token,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object?> get props => [provider, token, firstName, lastName];
}

class SocialRegisterSubmitted extends AuthEvent {
  final Map<String, dynamic> data;
  final String? nameToUpdate;

  SocialRegisterSubmitted(this.data, {this.nameToUpdate});

  @override
  List<Object?> get props => [data, nameToUpdate];
}

class FetchUserRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String userId;
  final Map<String, dynamic> data;

  UpdateProfileRequested({required this.userId, required this.data});

  @override
  @override
  List<Object?> get props => [userId, data];
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class SavePinSubmitted extends AuthEvent {
  final String pin;
  SavePinSubmitted(this.pin);

  @override
  List<Object?> get props => [pin];
}

class VerifyPinSubmitted extends AuthEvent {
  final String pin;
  VerifyPinSubmitted(this.pin);

  @override
  List<Object?> get props => [pin];
}

class ChangePinRequested extends AuthEvent {
  final String oldPin;
  final String newPin;

  ChangePinRequested({required this.oldPin, required this.newPin});

  @override
  List<Object?> get props => [oldPin, newPin];
}

class UpdateBiometricStatusRequested extends AuthEvent {
  final bool enabled;
  UpdateBiometricStatusRequested(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SyncBiometricStatusRequested extends AuthEvent {}

class ResetPasswordSubmitted extends AuthEvent {
  final String identifier;
  final String token;
  final String newPassword;

  ResetPasswordSubmitted({
    required this.identifier,
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object> get props => [identifier, token, newPassword];
}

class ValidateResetToken extends AuthEvent {
  final String identifier;
  final String token;

  ValidateResetToken({required this.identifier, required this.token});

  @override
  List<Object> get props => [identifier, token];
}

class ResetPinSubmitted extends AuthEvent {
  final String identifier;
  final String token;
  final String newPin;

  ResetPinSubmitted({
    required this.identifier,
    required this.token,
    required this.newPin,
  });

  @override
  List<Object> get props => [identifier, token, newPin];
}

class ForgotPinRequested extends AuthEvent {
  final String identifier;
  ForgotPinRequested(this.identifier);

  @override
  List<Object> get props => [identifier];
}

class ForgotPasswordRequested extends AuthEvent {
  final String identifier;
  ForgotPasswordRequested(this.identifier);

  @override
  List<Object> get props => [identifier];
}

class UpdateProfilePictureRequested extends AuthEvent {
  final String imagePath;
  UpdateProfilePictureRequested(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}
