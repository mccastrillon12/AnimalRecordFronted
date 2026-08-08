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
import 'package:animal_record/features/auth/domain/usecases/logout_session_usecase.dart';
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
import 'package:animal_record/features/auth/domain/usecases/confirm_profile_picture_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:animal_record/features/auth/domain/repositories/user_cache.dart';
import 'package:animal_record/core/services/app_logger.dart';

// ── Part files containing handler implementations ────────────────────────
part '_auth_bloc_login.dart';
part '_auth_bloc_registration.dart';
part '_auth_bloc_security.dart';
part '_auth_bloc_profile.dart';
part '_auth_bloc_session.dart';

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
  final LogoutSessionUseCase logoutSessionUseCase;
  final TokenStorage tokenStorage;
  final UserCache userCache;
  final AppLogger logger;
  final ConfirmProfilePictureUseCase confirmProfilePictureUseCase;
  final UploadProfilePictureUseCase uploadProfilePictureUseCase;

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
    required this.logoutSessionUseCase,
    required this.tokenStorage,
    required this.userCache,
    required this.logger,
    required this.confirmProfilePictureUseCase,
    required this.uploadProfilePictureUseCase,
  }) : super(AuthInitial()) {
    // ── Login / Auth ──────────────────────────────────────
    on<FetchUserRequested>((e, emit) => _onFetchUserRequested(this, e, emit));
    on<LoginSubmitted>((e, emit) => _onLoginSubmitted(this, e, emit));
    on<VerifyCodeSubmitted>((e, emit) => _onVerifyCodeSubmitted(this, e, emit));
    on<SocialAuthChecked>((e, emit) => _onSocialAuthChecked(this, e, emit));
    on<SocialRegisterSubmitted>(
      (e, emit) => _onSocialRegisterSubmitted(this, e, emit),
    );
    on<LogoutRequested>((e, emit) => _onLogoutRequested(this, e, emit));

    // ── Registration ──────────────────────────────────────
    on<SignUpSubmitted>((e, emit) => _onSignUpSubmitted(this, e, emit));
    on<CheckIdentificationExists>(
      (e, emit) => _onCheckIdentificationExists(this, e, emit),
    );
    on<CheckAvailabilityRequested>(
      (e, emit) => _onCheckAvailabilityRequested(this, e, emit),
    );
    on<ResendCodeSubmitted>((e, emit) => _onResendCodeSubmitted(this, e, emit));

    // ── Security (PIN / Biometric / Password) ─────────────
    on<SavePinSubmitted>((e, emit) => _onSavePinSubmitted(this, e, emit));
    on<VerifyPinSubmitted>((e, emit) => _onVerifyPinSubmitted(this, e, emit));
    on<ChangePinRequested>((e, emit) => _onChangePinRequested(this, e, emit));
    on<ForgotPinRequested>((e, emit) => _onForgotPinRequested(this, e, emit));
    on<ResetPinSubmitted>((e, emit) => _onResetPinSubmitted(this, e, emit));
    on<UpdateBiometricStatusRequested>(
      (e, emit) => _onUpdateBiometricStatusRequested(this, e, emit),
    );
    on<SyncBiometricStatusRequested>(
      (e, emit) => _onSyncBiometricStatusRequested(this, e, emit),
    );
    on<ChangePasswordRequested>(
      (e, emit) => _onChangePasswordRequested(this, e, emit),
    );
    on<ResetPasswordSubmitted>(
      (e, emit) => _onResetPasswordSubmitted(this, e, emit),
    );
    on<ValidateResetToken>((e, emit) => _onValidateResetToken(this, e, emit));
    on<ForgotPasswordRequested>(
      (e, emit) => _onForgotPasswordRequested(this, e, emit),
    );

    // ── Profile ───────────────────────────────────────────
    on<UpdateProfileRequested>(
      (e, emit) => _onUpdateProfileRequested(this, e, emit),
    );
    on<UpdateProfilePictureRequested>(
      (e, emit) => _onUpdateProfilePicture(this, e, emit),
    );
    on<DeleteProfilePictureRequested>(
      (e, emit) => _onDeleteProfilePicture(this, e, emit),
    );
  }
}
