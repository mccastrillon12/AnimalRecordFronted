import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;
  final bool isUpdating;
  final String? updateError;
  final bool pinSaveSuccess;
  final bool pinVerifiedSuccess;
  final bool pinChangeSuccess;
  final bool isBiometricEnabled;
  final bool biometricUpdateSuccess;
  final bool isUploadingPicture;
  final String? profilePictureError;

  AuthSuccess(
    this.user, {
    this.isUpdating = false,
    this.updateError,
    this.pinSaveSuccess = false,
    this.pinVerifiedSuccess = false,
    this.pinChangeSuccess = false,
    this.isBiometricEnabled = false,
    this.biometricUpdateSuccess = false,
    this.isUploadingPicture = false,
    this.profilePictureError,
  });

  @override
  List<Object?> get props => [
    user,
    isUpdating,
    updateError,
    pinSaveSuccess,
    pinVerifiedSuccess,
    pinChangeSuccess,
    isBiometricEnabled,
    biometricUpdateSuccess,
    isUploadingPicture,
    profilePictureError,
  ];

  AuthSuccess copyWith({
    UserEntity? user,
    bool? isUpdating,
    String? updateError,
    bool? pinSaveSuccess,
    bool? pinVerifiedSuccess,
    bool? pinChangeSuccess,
    bool? isBiometricEnabled,
    bool? biometricUpdateSuccess,
    bool? isUploadingPicture,
    String? profilePictureError,
  }) {
    return AuthSuccess(
      user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError ?? this.updateError,
      pinSaveSuccess: pinSaveSuccess ?? this.pinSaveSuccess,
      pinVerifiedSuccess: pinVerifiedSuccess ?? this.pinVerifiedSuccess,
      pinChangeSuccess: pinChangeSuccess ?? this.pinChangeSuccess,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      biometricUpdateSuccess:
          biometricUpdateSuccess ?? this.biometricUpdateSuccess,
      isUploadingPicture: isUploadingPicture ?? this.isUploadingPicture,
      profilePictureError: profilePictureError ?? this.profilePictureError,
    );
  }
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
  PasswordChangeSuccess(super.user, {super.isBiometricEnabled});
}

class ResetPasswordSuccess extends AuthState {}

class ResetTokenValid extends AuthState {}

class ResetTokenInvalid extends AuthState {}

class ForgotPasswordSuccess extends AuthState {}

class ForgotPinSuccess extends AuthState {}

class ResetPinSuccess extends AuthState {}
