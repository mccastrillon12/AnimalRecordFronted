import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/domain/usecases/register_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/login_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/resend_code_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/check_identification_exists_usecase.dart';
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
import 'package:animal_record/core/services/token_storage.dart';
import 'dart:convert';
import 'package:animal_record/features/auth/data/models/user_model.dart';

/// AuthBloc manages all authentication, profile, PIN, and biometric operations.
///
/// Organized into sections:
/// - Authentication (Login, Register, Verification, Social Auth)
/// - Profile Management (Fetch, Update, Password)
/// - PIN Management (Save, Verify, Change)
/// - Biometric Management (Activate, Sync)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;
  final ResendCodeUseCase resendCodeUseCase;
  final CheckIdentificationExistsUseCase checkIdentificationExistsUseCase;
  final CheckSocialAuthUseCase checkSocialAuthUseCase;
  final RegisterSocialUseCase registerSocialUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final SavePinUseCase savePinUseCase;
  final VerifyPinUseCase verifyPinUseCase;
  final ChangePinUseCase changePinUseCase;
  final UpdateBiometricStatusUseCase updateBiometricStatusUseCase;
  final GetBiometricStatusUseCase getBiometricStatusUseCase;
  final LogoutUseCase logoutUseCase;
  final TokenStorage tokenStorage;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.verifyCodeUseCase,
    required this.resendCodeUseCase,
    required this.checkIdentificationExistsUseCase,
    required this.checkSocialAuthUseCase,
    required this.registerSocialUseCase,
    required this.getUserProfileUseCase,
    required this.updateProfileUseCase,
    required this.changePasswordUseCase,
    required this.savePinUseCase,
    required this.verifyPinUseCase,
    required this.changePinUseCase,
    required this.updateBiometricStatusUseCase,
    required this.getBiometricStatusUseCase,
    required this.logoutUseCase,
    required this.tokenStorage,
  }) : super(AuthInitial()) {
    // ═══════════════════════════════════════════════════════════════
    // PROFILE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /// Fetches user profile from cache and backend, syncs biometric status
    on<FetchUserRequested>(_onFetchUserRequested);

    /// Updates user profile (name, phone, address, etc.)
    on<UpdateProfileRequested>(_onUpdateProfileRequested);

    /// Changes user password
    on<ChangePasswordRequested>(_onChangePasswordRequested);

    /// Logs out user, clears tokens and navigates to login
    on<LogoutRequested>(_onLogoutRequested);

    // ═══════════════════════════════════════════════════════════════
    // AUTHENTICATION - Email/Password
    // ═══════════════════════════════════════════════════════════════

    /// Registers new user with email/password
    on<SignUpSubmitted>(_onSignUpSubmitted);

    /// Logs in user with email/password
    on<LoginSubmitted>(_onLoginSubmitted);

    /// Verifies email code after registration
    on<VerifyCodeSubmitted>(_onVerifyCodeSubmitted);

    /// Checks if an identification number already exists
    on<CheckIdentificationExists>(_onCheckIdentificationExists);

    /// Resends verification code to email
    on<ResendCodeSubmitted>(_onResendCodeSubmitted);

    // ═══════════════════════════════════════════════════════════════
    // AUTHENTICATION - Social (Google/Microsoft)
    // ═══════════════════════════════════════════════════════════════

    /// Checks if social account already exists or needs registration
    on<SocialAuthChecked>(_onSocialAuthChecked);

    /// Completes social registration with additional data
    on<SocialRegisterSubmitted>(_onSocialRegisterSubmitted);

    // ═══════════════════════════════════════════════════════════════
    // PIN MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /// Saves new PIN for the authenticated user
    on<SavePinSubmitted>(_onSavePinSubmitted);

    /// Verifies PIN and logs user in
    on<VerifyPinSubmitted>(_onVerifyPinSubmitted);

    /// Changes existing PIN
    on<ChangePinRequested>(_onChangePinRequested);

    // ═══════════════════════════════════════════════════════════════
    // BIOMETRIC MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /// Updates biometric authentication status (enable/disable)
    on<UpdateBiometricStatusRequested>(_onUpdateBiometricStatusRequested);

    /// Syncs biometric status from backend
    on<SyncBiometricStatusRequested>(_onSyncBiometricStatusRequested);
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE MANAGEMENT HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onFetchUserRequested(
    FetchUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    final cachedUser = await tokenStorage.getUserData();
    bool loadedFromCache = false;

    if (cachedUser != null) {
      try {
        final userMap = json.decode(cachedUser);
        final user = UserModel.fromJson(userMap);

        // Only emit if we are not already in AuthSuccess with the same user
        final currentState = state;
        if (currentState is! AuthSuccess || currentState.user != user) {
          emit(AuthSuccess(user));
        }
        loadedFromCache = true;
      } catch (e) {}
    }

    final userId = await tokenStorage.getUserId();
    if (userId != null) {
      final result = await getUserProfileUseCase(userId);

      await result.fold(
        (failure) async {
          if (state is! AuthSuccess) {
            emit(AuthError('Session expired or invalid'));
          }
        },
        (user) async {
          await _saveUserToCache(user);

          final currentState = state;
          if (currentState is! AuthSuccess || currentState.user != user) {
            await _emitAuthSuccessWithBiometrics(user, emit);
          }
        },
      );
    } else if (!loadedFromCache) {
      emit(
        AuthError(
          '¡Cuenta creada con éxito! inicia sesión y comienza a usar AnimalRecord.',
        ),
      );
    }
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    UserEntity? currentUser;

    if (currentState is AuthSuccess) {
      currentUser = currentState.user;
      emit(AuthSuccess(currentUser, isUpdating: true));
    } else {
      emit(AuthLoading());
    }

    final result = await updateProfileUseCase(
      id: event.userId,
      data: event.data,
    );

    await result.fold(
      (failure) async {
        if (currentUser != null) {
          emit(
            AuthSuccess(
              currentUser,
              isUpdating: false,
              updateError: failure.message,
            ),
          );
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        await _saveUserToCache(user);
        emit(AuthSuccess(user, isUpdating: false));
      },
    );
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    UserEntity? currentUser;

    if (currentState is AuthSuccess) {
      currentUser = currentState.user;
      emit(AuthSuccess(currentUser, isUpdating: true));
    } else {
      emit(AuthLoading());
    }

    final result = await changePasswordUseCase(
      event.oldPassword,
      event.newPassword,
    );

    await result.fold(
      (failure) async {
        if (currentUser != null) {
          emit(
            AuthSuccess(
              currentUser,
              isUpdating: false,
              updateError: failure.message,
            ),
          );
        } else {
          emit(AuthError(failure.message));
        }
      },
      (_) async {
        if (currentUser != null) {
          emit(PasswordChangeSuccess(currentUser));
        } else {
          emit(PasswordChangeSuccess(UserModel.empty()));
        }
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await logoutUseCase();
    emit(AuthInitial());
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATION - Email/Password HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(event.userData);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async => emit(AuthSuccess(user)),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(event.credentials);

    await result.fold(
      (failure) async {
        if (failure.message.contains('UserNotVerified')) {
          int? timeRemaining;
          try {
            final match = RegExp(
              r'UserNotVerified:(\d+)',
            ).firstMatch(failure.message);
            if (match != null) {
              timeRemaining = int.tryParse(match.group(1)!);
            }
          } catch (_) {}
          emit(AuthUserNotVerified(timeRemaining: timeRemaining));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        await _saveUserToCache(user);
        await _emitAuthSuccessWithBiometrics(user, emit);
      },
    );
  }

  Future<void> _onVerifyCodeSubmitted(
    VerifyCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await verifyCodeUseCase(event.params);

    await result.fold((failure) async => emit(AuthError(failure.message)), (
      user,
    ) async {
      await _saveUserToCache(user);
      await _emitAuthSuccessWithBiometrics(user, emit);
    });
  }

  Future<void> _onCheckIdentificationExists(
    CheckIdentificationExists event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await checkIdentificationExistsUseCase(
      event.identificationNumber,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (exists) async => emit(IdentificationCheckResult(exists)),
    );
  }

  Future<void> _onResendCodeSubmitted(
    ResendCodeSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final result = await resendCodeUseCase(event.identifier);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async => emit(ResendCodeSuccess()),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATION - Social HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onSocialAuthChecked(
    SocialAuthChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await checkSocialAuthUseCase(
      provider: event.provider,
      token: event.token,
    );

    await result.fold((failure) async => emit(AuthError(failure.message)), (
      response,
    ) async {
      if (response['status'] == 'NEED_REGISTER') {
        emit(SocialAuthNeedRegister(response, provider: event.provider));
      } else if (response['status'] == 'SUCCESS') {
        final user = response['user'];
        await _saveUserToCache(user);
        await _emitAuthSuccessWithBiometrics(user, emit);
      } else {
        emit(AuthError('Respuesta inesperada del servidor'));
      }
    });
  }

  Future<void> _onSocialRegisterSubmitted(
    SocialRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerSocialUseCase(event.data);

    await result.fold((failure) async => emit(AuthError(failure.message)), (
      user,
    ) async {
      await _saveUserToCache(user);
      await _emitAuthSuccessWithBiometrics(user, emit);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PIN MANAGEMENT HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onSavePinSubmitted(
    SavePinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    UserEntity? currentUser;

    if (currentState is AuthSuccess) {
      currentUser = currentState.user;
    }

    emit(AuthLoading());

    final result = await savePinUseCase(event.pin);

    await result.fold(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (_) async {
        if (currentUser != null) {
          emit(AuthSuccess(currentUser, pinSaveSuccess: true));
        } else {
          add(FetchUserRequested());
        }
      },
    );
  }

  Future<void> _onVerifyPinSubmitted(
    VerifyPinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await verifyPinUseCase(event.pin);

    await result.fold(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (_) async {
        final userId = await tokenStorage.getUserId();
        if (userId != null) {
          final userResult = await getUserProfileUseCase(userId);
          await userResult.fold(
            (failure) async {
              add(FetchUserRequested());
            },
            (user) async {
              await _saveUserToCache(user);
              emit(AuthSuccess(user, pinVerifiedSuccess: true));
            },
          );
        } else {
          add(FetchUserRequested());
        }
      },
    );
  }

  Future<void> _onChangePinRequested(
    ChangePinRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthSuccess) {
      emit(AuthError('Debe estar autenticado para cambiar el PIN'));
      return;
    }

    emit(AuthSuccess(currentState.user, isUpdating: true));

    final result = await changePinUseCase(event.oldPin, event.newPin);

    await result.fold(
      (failure) async {
        emit(
          AuthSuccess(
            currentState.user,
            isUpdating: false,
            updateError: failure.message,
          ),
        );
        emit(AuthError(failure.message));
      },
      (_) async {
        emit(
          AuthSuccess(
            currentState.user,
            isUpdating: false,
            pinChangeSuccess: true,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BIOMETRIC MANAGEMENT HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onUpdateBiometricStatusRequested(
    UpdateBiometricStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await updateBiometricStatusUseCase(event.enabled);

    await result.fold((failure) async => null, (_) async {
      final userId = await tokenStorage.getUserId();
      if (userId != null) {
        await tokenStorage.saveBiometricsEnabledForUser(userId, event.enabled);

        final currentState = state;
        if (currentState is AuthSuccess) {
          emit(
            currentState.copyWith(
              isBiometricEnabled: event.enabled,
              biometricUpdateSuccess: true,
            ),
          );

          emit(
            currentState.copyWith(
              isBiometricEnabled: event.enabled,
              biometricUpdateSuccess: false,
            ),
          );
        }
      }
    });
  }

  Future<void> _onSyncBiometricStatusRequested(
    SyncBiometricStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final userId = await tokenStorage.getUserId();
    if (userId != null) {
      await _syncBiometricStatus(userId, emit);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Saves user data to encrypted local cache
  Future<void> _saveUserToCache(UserEntity user) async {
    if (user is UserModel) {
      await tokenStorage.saveUserData(json.encode(user.toJson()));
    }
  }

  /// Emits AuthSuccess with user and synced biometric status
  Future<void> _emitAuthSuccessWithBiometrics(
    UserEntity user,
    Emitter<AuthState> emit,
  ) async {
    await _syncBiometricStatus(user.id, emit);
    final isEnabled = await tokenStorage.getBiometricsEnabledForUser(user.id);
    emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
  }

  /// Syncs biometric status from backend and updates local cache
  Future<void> _syncBiometricStatus(
    String userId,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await getBiometricStatusUseCase();

      await result.fold((failure) async => null, (isEnabled) async {
        await tokenStorage.saveBiometricsEnabledForUser(userId, isEnabled);

        final currentState = state;
        if (currentState is AuthSuccess) {
          emit(currentState.copyWith(isBiometricEnabled: isEnabled));
        }
      });
    } catch (e) {
      // Ignore errors during sync
    }
  }
}
