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
import 'package:animal_record/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/validate_password_token_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/forgot_pin_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/reset_pin_usecase.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'dart:convert';
import 'package:animal_record/features/auth/data/models/user_model.dart';

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
  }) : super(AuthInitial()) {
    on<FetchUserRequested>(_onFetchUserRequested);

    on<UpdateProfileRequested>(_onUpdateProfileRequested);

    on<ChangePasswordRequested>(_onChangePasswordRequested);

    on<LogoutRequested>(_onLogoutRequested);

    on<SignUpSubmitted>(_onSignUpSubmitted);

    on<LoginSubmitted>(_onLoginSubmitted);

    on<VerifyCodeSubmitted>(_onVerifyCodeSubmitted);

    on<CheckIdentificationExists>(_onCheckIdentificationExists);

    on<ResendCodeSubmitted>(_onResendCodeSubmitted);

    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);

    on<ValidateResetToken>(_onValidateResetToken);

    on<ForgotPasswordRequested>(_onForgotPasswordRequested);

    on<SocialAuthChecked>(_onSocialAuthChecked);

    on<SocialRegisterSubmitted>(_onSocialRegisterSubmitted);

    on<SavePinSubmitted>(_onSavePinSubmitted);

    on<VerifyPinSubmitted>(_onVerifyPinSubmitted);

    on<ChangePinRequested>(_onChangePinRequested);

    on<ForgotPinRequested>(_onForgotPinRequested);

    on<ResetPinSubmitted>(_onResetPinSubmitted);

    on<UpdateBiometricStatusRequested>(_onUpdateBiometricStatusRequested);

    on<SyncBiometricStatusRequested>(_onSyncBiometricStatusRequested);
  }

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
      emit(
        AuthSuccess(
          currentUser,
          isUpdating: true,
          isBiometricEnabled: currentState.isBiometricEnabled,
        ),
      );
    } else {
      emit(AuthLoading());
    }

    final result = await updateProfileUseCase(
      id: event.userId,
      data: event.data,
    );

    await result.fold(
      (failure) async {
        if (currentUser != null && currentState is AuthSuccess) {
          emit(
            AuthSuccess(
              currentUser,
              isUpdating: false,
              updateError: failure.message,
              isBiometricEnabled: currentState.isBiometricEnabled,
            ),
          );
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        await _saveUserToCache(user);
        emit(
          AuthSuccess(
            user,
            isUpdating: false,
            isBiometricEnabled: currentState is AuthSuccess
                ? currentState.isBiometricEnabled
                : false,
          ),
        );
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
      emit(
        AuthSuccess(
          currentUser,
          isUpdating: true,
          isBiometricEnabled: currentState.isBiometricEnabled,
        ),
      );
    } else {
      emit(AuthLoading());
    }

    final result = await changePasswordUseCase(
      event.oldPassword,
      event.newPassword,
    );

    await result.fold(
      (failure) async {
        if (currentUser != null && currentState is AuthSuccess) {
          emit(
            AuthSuccess(
              currentUser,
              isUpdating: false,
              updateError: failure.message,
              isBiometricEnabled: currentState.isBiometricEnabled,
            ),
          );
        } else {
          emit(AuthError(failure.message));
        }
      },
      (_) async {
        if (currentUser != null) {
          emit(
            PasswordChangeSuccess(
              currentUser,
              isBiometricEnabled: currentState is AuthSuccess
                  ? currentState.isBiometricEnabled
                  : false,
            ),
          );
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
        if (currentUser != null && currentState is AuthSuccess) {
          emit(
            AuthSuccess(
              currentUser,
              pinSaveSuccess: true,
              isBiometricEnabled: currentState.isBiometricEnabled,
            ),
          );
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
              final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
                user.id,
              );
              emit(
                AuthSuccess(
                  user,
                  pinVerifiedSuccess: true,
                  isBiometricEnabled: isEnabled,
                ),
              );
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

    emit(
      AuthSuccess(
        currentState.user,
        isUpdating: true,
        isBiometricEnabled: currentState.isBiometricEnabled,
      ),
    );

    final result = await changePinUseCase(event.oldPin, event.newPin);

    await result.fold(
      (failure) async {
        emit(
          AuthSuccess(
            currentState.user,
            isUpdating: false,
            updateError: failure.message,
            isBiometricEnabled: currentState.isBiometricEnabled,
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
            isBiometricEnabled: currentState.isBiometricEnabled,
          ),
        );
      },
    );
  }

  Future<void> _onForgotPinRequested(
    ForgotPinRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await forgotPinUseCase(event.identifier);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async => emit(ForgotPinSuccess()),
    );
  }

  Future<void> _onResetPinSubmitted(
    ResetPinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await resetPinUseCase(
      event.identifier,
      event.token,
      event.newPin,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async => emit(ResetPinSuccess()),
    );
  }

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

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await resetPasswordUseCase(
      event.identifier,
      event.token,
      event.newPassword,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> _onValidateResetToken(
    ValidateResetToken event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await validatePasswordTokenUseCase(
      event.identifier,
      event.token,
    );

    await result.fold(
      (failure) async {
        if (failure.message.toLowerCase().contains('invalid') ||
            failure.message.toLowerCase().contains('expired') ||
            failure.message.toLowerCase().contains('inválido') ||
            failure.message.toLowerCase().contains('expirado')) {
          emit(ResetTokenInvalid());
        } else {
          emit(ResetTokenInvalid());
        }
      },
      (isValid) async {
        if (isValid) {
          emit(ResetTokenValid());
        } else {
          emit(ResetTokenInvalid());
        }
      },
    );
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await forgotPasswordUseCase(event.identifier);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async => emit(ForgotPasswordSuccess()),
    );
  }

  Future<void> _saveUserToCache(UserEntity user) async {
    if (user is UserModel) {
      await tokenStorage.saveUserData(json.encode(user.toJson()));
    }
  }

  Future<void> _emitAuthSuccessWithBiometrics(
    UserEntity user,
    Emitter<AuthState> emit,
  ) async {
    await _syncBiometricStatus(user.id, emit);
    final isEnabled = await tokenStorage.getBiometricsEnabledForUser(user.id);
    emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
  }

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
    } catch (e) {}
  }
}
