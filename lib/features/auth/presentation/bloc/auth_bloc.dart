import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/domain/usecases/register_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/login_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/resend_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_identification_exists_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_availability_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_social_auth_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/register_social_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_user_profile_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/logout_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/verify_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/save_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/change_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/update_biometric_status_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/get_biometric_status_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/reset_pin_usecase.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/features/auth/domain/usecases/get_profile_picture_upload_url_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/confirm_profile_picture_usecase.dart';
import 'package:animal_record/core/services/s3_upload_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';

import 'package:animal_record/features/auth/data/models/user_model.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:animal_record/core/services/microsoft_auth_service.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';

// ── Part files containing handler implementations ────────────────────────
part '_auth_bloc_login.dart';
part '_auth_bloc_registration.dart';
part '_auth_bloc_security.dart';
part '_auth_bloc_profile.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;
  final ResendCodeUseCase resendCodeUseCase;
  final CheckIdentificationExistsUseCase checkIdentificationExistsUseCase;
  final CheckAvailabilityUseCase checkAvailabilityUseCase;
  final CheckSocialAuthUseCase checkSocialAuthUseCase;
  final RegisterSocialUseCase registerSocialUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final ValidatePasswordTokenUseCase validatePasswordTokenUseCase;
  final SavePinUseCase savePinUseCase;
  final VerifyPinUseCase verifyPinUseCase;
  final ChangePinUseCase changePinUseCase;
  final UpdateBiometricStatusUseCase updateBiometricStatusUseCase;
  final GetBiometricStatusUseCase getBiometricStatusUseCase;
  final ForgotPinUseCase forgotPinUseCase;
  final ResetPinUseCase resetPinUseCase;
  final LogoutUseCase logoutUseCase;
  final TokenStorage tokenStorage;
  final GetProfilePictureUploadUrlUseCase getProfilePictureUploadUrlUseCase;
  final ConfirmProfilePictureUseCase confirmProfilePictureUseCase;
  final S3UploadService s3UploadService;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.verifyCodeUseCase,
    required this.resendCodeUseCase,
    required this.checkIdentificationExistsUseCase,
    required this.checkAvailabilityUseCase,
    required this.checkSocialAuthUseCase,
    required this.registerSocialUseCase,
    required this.getUserProfileUseCase,
    required this.updateProfileUseCase,
    required this.changePasswordUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.validatePasswordTokenUseCase,
    required this.savePinUseCase,
    required this.verifyPinUseCase,
    required this.changePinUseCase,
    required this.updateBiometricStatusUseCase,
    required this.getBiometricStatusUseCase,
    required this.forgotPinUseCase,
    required this.resetPinUseCase,
    required this.logoutUseCase,
    required this.tokenStorage,
    required this.getProfilePictureUploadUrlUseCase,
    required this.confirmProfilePictureUseCase,
    required this.s3UploadService,
  }) : super(AuthInitial()) {
    // ── Login / Auth ──────────────────────────────────────
    on<FetchUserRequested>((e, emit) => _onFetchUserRequested(this, e, emit));
    on<LoginSubmitted>((e, emit) => _onLoginSubmitted(this, e, emit));
    on<VerifyCodeSubmitted>((e, emit) => _onVerifyCodeSubmitted(this, e, emit));
    on<SocialAuthChecked>((e, emit) => _onSocialAuthChecked(this, e, emit));
    on<SocialRegisterSubmitted>((e, emit) => _onSocialRegisterSubmitted(this, e, emit));
    on<LogoutRequested>((e, emit) => _onLogoutRequested(this, e, emit));

    // ── Registration ──────────────────────────────────────
    on<SignUpSubmitted>((e, emit) => _onSignUpSubmitted(this, e, emit));
    on<CheckIdentificationExists>((e, emit) => _onCheckIdentificationExists(this, e, emit));
    on<CheckAvailabilityRequested>((e, emit) => _onCheckAvailabilityRequested(this, e, emit));
    on<ResendCodeSubmitted>((e, emit) => _onResendCodeSubmitted(this, e, emit));

    // ── Security (PIN / Biometric / Password) ─────────────
    on<SavePinSubmitted>((e, emit) => _onSavePinSubmitted(this, e, emit));
    on<VerifyPinSubmitted>((e, emit) => _onVerifyPinSubmitted(this, e, emit));
    on<ChangePinRequested>((e, emit) => _onChangePinRequested(this, e, emit));
    on<ForgotPinRequested>((e, emit) => _onForgotPinRequested(this, e, emit));
    on<ResetPinSubmitted>((e, emit) => _onResetPinSubmitted(this, e, emit));
    on<UpdateBiometricStatusRequested>((e, emit) => _onUpdateBiometricStatusRequested(this, e, emit));
    on<SyncBiometricStatusRequested>((e, emit) => _onSyncBiometricStatusRequested(this, e, emit));
    on<ChangePasswordRequested>((e, emit) => _onChangePasswordRequested(this, e, emit));
    on<ResetPasswordSubmitted>((e, emit) => _onResetPasswordSubmitted(this, e, emit));
    on<ValidateResetToken>((e, emit) => _onValidateResetToken(this, e, emit));
    on<ForgotPasswordRequested>((e, emit) => _onForgotPasswordRequested(this, e, emit));

    // ── Profile ───────────────────────────────────────────
    on<UpdateProfileRequested>((e, emit) => _onUpdateProfileRequested(this, e, emit));
    on<UpdateProfilePictureRequested>((e, emit) => _onUpdateProfilePicture(this, e, emit));
    on<DeleteProfilePictureRequested>((e, emit) => _onDeleteProfilePicture(this, e, emit));
  }
}

// ── Shared helpers (used by all part files) ──────────────────────────────

Future<void> _saveUserToCacheImpl(AuthBloc bloc, UserEntity user) async {
  final userModel = user is UserModel
      ? user
      : UserModel(
          id: user.id,
          name: user.name,
          identificationType: user.identificationType,
          identificationNumber: user.identificationNumber,
          country: user.country,
          countryId: user.countryId,
          departmentId: user.departmentId,
          city: user.city,
          cityId: user.cityId,
          address: user.address,
          email: user.email,
          cellPhone: user.cellPhone,
          professionalCard: user.professionalCard,
          animalTypes: user.animalTypes,
          services: user.services,
          isHomeDelivery: user.isHomeDelivery,
          roles: user.roles,
          authMethod: user.authMethod,
          isVerified: user.isVerified,
          profilePicture: user.profilePicture,
          securityLastUpdated: user.securityLastUpdated,
        );
  await bloc.tokenStorage.saveUserData(json.encode(userModel.toJson()));
}

Future<void> _emitAuthSuccessWithBiometricsImpl(
  AuthBloc bloc,
  UserEntity user,
  Emitter<AuthState> emit,
) async {
  await _syncBiometricStatusImpl(bloc, user.id, emit);
  final isEnabled = await bloc.tokenStorage.getBiometricsEnabledForUser(user.id);
  emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
}

Future<void> _syncBiometricStatusImpl(
  AuthBloc bloc,
  String userId,
  Emitter<AuthState> emit,
) async {
  try {
    final result = await bloc.getBiometricStatusUseCase();

    await result.fold((failure) async => null, (isEnabled) async {
      await bloc.tokenStorage.saveBiometricsEnabledForUser(userId, isEnabled);

      final currentState = bloc.state;
      if (currentState is AuthSuccess) {
        emit(currentState.copyWith(isBiometricEnabled: isEnabled));
      }
    });
  } catch (e) {
    // Non-critical – biometric sync failure should not block UX
  }
}
