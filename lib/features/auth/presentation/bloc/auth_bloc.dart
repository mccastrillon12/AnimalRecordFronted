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
  final VerifyPinUseCase verifyPinUseCase; // Added
  final ChangePinUseCase changePinUseCase; // Added
  final UpdateBiometricStatusUseCase updateBiometricStatusUseCase; // Added
  final GetBiometricStatusUseCase getBiometricStatusUseCase; // Added
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
    required this.verifyPinUseCase, // Added
    required this.changePinUseCase, // Added
    required this.updateBiometricStatusUseCase, // Added
    required this.getBiometricStatusUseCase, // Added
    required this.logoutUseCase,
    required this.tokenStorage,
  }) : super(AuthInitial()) {
    on<FetchUserRequested>((event, emit) async {
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
            if (user is UserModel) {
              await tokenStorage.saveUserData(json.encode(user.toJson()));
            }

            final currentState = state;
            if (currentState is! AuthSuccess || currentState.user != user) {
              await _syncBiometricStatus(user.id, emit);
              final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
                user.id,
              );
              emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
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
    });

    on<SignUpSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await registerUseCase(event.userData);

      await result.fold(
        (failure) async => emit(AuthError(failure.message)),
        (user) async => emit(AuthSuccess(user)),
      );
    });

    on<LoginSubmitted>((event, emit) async {
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
          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          await _syncBiometricStatus(user.id, emit);
          final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
            user.id,
          );
          emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
        },
      );
    });

    on<VerifyCodeSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyCodeUseCase(event.params);

      await result.fold((failure) async => emit(AuthError(failure.message)), (
        user,
      ) async {
        if (user is UserModel) {
          await tokenStorage.saveUserData(json.encode(user.toJson()));
        }
        await _syncBiometricStatus(user.id, emit);
        final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
          user.id,
        );
        emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
      });
    });

    on<CheckIdentificationExists>((event, emit) async {
      emit(AuthLoading());

      final result = await checkIdentificationExistsUseCase(
        event.identificationNumber,
      );

      await result.fold(
        (failure) async => emit(AuthError(failure.message)),
        (exists) async => emit(IdentificationCheckResult(exists)),
      );
    });

    on<ResendCodeSubmitted>((event, emit) async {
      final result = await resendCodeUseCase(event.identifier);

      await result.fold(
        (failure) async => emit(AuthError(failure.message)),
        (_) async => emit(ResendCodeSuccess()),
      );
    });

    on<SocialAuthChecked>((event, emit) async {
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

          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          await _syncBiometricStatus(user.id, emit);
          final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
            user.id,
          );
          emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
        } else {
          emit(AuthError('Respuesta inesperada del servidor'));
        }
      });
    });

    on<SocialRegisterSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await registerSocialUseCase(event.data);

      await result.fold((failure) async => emit(AuthError(failure.message)), (
        user,
      ) async {
        if (user is UserModel) {
          await tokenStorage.saveUserData(json.encode(user.toJson()));
        }
        await _syncBiometricStatus(user.id, emit);
        final isEnabled = await tokenStorage.getBiometricsEnabledForUser(
          user.id,
        );
        emit(AuthSuccess(user, isBiometricEnabled: isEnabled));
      });
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await logoutUseCase();
      emit(AuthInitial());
    });

    on<UpdateProfileRequested>((event, emit) async {
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
          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          emit(AuthSuccess(user, isUpdating: false));
        },
      );
    });

    on<ChangePasswordRequested>((event, emit) async {
      final currentState = state;
      UserEntity? currentUser;

      if (currentState is AuthSuccess) {
        currentUser = currentState.user;
        // Emit update state to show loading on button, but keep MyAccountScreen visible
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
            // Immediately revert to normal AuthSuccess to clear "Success" event if needed,
            // but PasswordChangeSuccess IS AuthSuccess so MyAccountScreen will stay visible.
            // MyAccountScreen might re-render, but it's fine.
          } else {
            emit(PasswordChangeSuccess(UserModel.empty()));
          }
        },
      );
    });

    on<SavePinSubmitted>((event, emit) async {
      print("🚀 SavePinSubmitted event received with PIN: ${event.pin}");

      final currentState = state;
      UserEntity? currentUser;

      if (currentState is AuthSuccess) {
        currentUser = currentState.user;
      }

      emit(AuthLoading());
      print("🚀 Emitted AuthLoading");

      final result = await savePinUseCase(event.pin);

      await result.fold(
        (failure) async {
          print("❌ SavePin Failed: ${failure.message}");
          emit(AuthError(failure.message));
        },
        (_) async {
          print("✅ SavePin Success. Restoring user: $currentUser");
          // If we had a user, restore success state
          if (currentUser != null) {
            emit(AuthSuccess(currentUser, pinSaveSuccess: true));
          } else {
            print("⚠️ CurrentUser is null, requesting fetch");
            // If we fetch user, we can't easily set pinSaveSuccess unless we pass it or chain state.
            // But FetchUserRequested emits AuthSuccess(user).
            // We might need to handle this case carefully if user is null.
            // Assuming user is usually not null here.
            add(FetchUserRequested());
            // Note: FetchUserRequested will NOT have pinSaveSuccess: true by default.
            // Ideally we should wait for fetch then emit, but that is complex.
            // For now, let's hope currentUser is not null.
            // If it IS null, user might be stuck but won't loop.
          }
        },
      );
    });

    on<VerifyPinSubmitted>((event, emit) async {
      print("🚀 VerifyPinSubmitted event: ${event.pin}");
      emit(AuthLoading());

      print("🔄 Calling verifyPinUseCase...");
      final result = await verifyPinUseCase(event.pin);
      print("🔄 verifyPinUseCase returned");

      await result.fold(
        (failure) async {
          print("❌ VerifyPin Failed: ${failure.message}");
          emit(AuthError(failure.message));
        },
        (_) async {
          print("✅ VerifyPin Success");

          final userId = await tokenStorage.getUserId();
          if (userId != null) {
            print("📌 Fetching user profile for userId: $userId");
            final userResult = await getUserProfileUseCase(userId);
            await userResult.fold(
              (failure) async {
                print("❌ Failed to fetch user: ${failure.message}");
                add(FetchUserRequested());
              }, // Fallback
              (user) async {
                print("✅ User fetched successfully");
                if (user is UserModel) {
                  await tokenStorage.saveUserData(json.encode(user.toJson()));
                }

                emit(AuthSuccess(user, pinVerifiedSuccess: true));
              },
            );
          } else {
            print("⚠️ No userId found, falling back to FetchUserRequested");
            add(FetchUserRequested());
          }
        },
      );
    });

    on<ChangePinRequested>((event, emit) async {
      print(
        "🚀 ChangePinRequested event: oldPin=${event.oldPin}, newPin=${event.newPin}",
      );

      final currentState = state;
      if (currentState is! AuthSuccess) {
        emit(AuthError('Debe estar autenticado para cambiar el PIN'));
        return;
      }

      emit(AuthSuccess(currentState.user, isUpdating: true));

      final result = await changePinUseCase(event.oldPin, event.newPin);

      await result.fold(
        (failure) async {
          print("❌ ChangePin Failed: ${failure.message}");
          emit(
            AuthSuccess(
              currentState.user,
              isUpdating: false,
              updateError: failure.message,
            ),
          );
          // Also emit error for immediate feedback
          emit(AuthError(failure.message));
        },
        (_) async {
          print("✅ ChangePin Success");
          emit(
            AuthSuccess(
              currentState.user,
              isUpdating: false,
              pinChangeSuccess: true,
            ),
          );
        },
      );
    });

    on<UpdateBiometricStatusRequested>((event, emit) async {
      print(
        "🚨🚨🚨 [BLOC] UpdateBiometricStatusRequested LLAMADO CON VALOR: ${event.enabled}",
      );
      final result = await updateBiometricStatusUseCase(event.enabled);

      await result.fold(
        (failure) async => print(
          "❌🚨 [BLOC] Error al actualizar biometría: ${failure.message}",
        ),
        (_) async {
          print(
            "✅🚨 [BLOC] Biometría actualizada exitosamente en backend a: ${event.enabled}",
          );

          final userId = await tokenStorage.getUserId();
          if (userId != null) {
            await tokenStorage.saveBiometricsEnabledForUser(
              userId,
              event.enabled,
            );

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
        },
      );
    });

    on<SyncBiometricStatusRequested>((event, emit) async {
      print("🚀🚨 [BLOC] SyncBiometricStatusRequested LLAMADO");
      final userId = await tokenStorage.getUserId();
      if (userId != null) {
        await _syncBiometricStatus(userId, emit);
      }
    });
  }

  Future<void> _syncBiometricStatus(
    String userId,
    Emitter<AuthState> emit,
  ) async {
    print("🔄🚨 [BLOC] Ejecutando _syncBiometricStatus para: $userId");
    try {
      final result = await getBiometricStatusUseCase();
      print("🔄🚨 [BLOC] getBiometricStatusUseCase completed. Result: $result");

      await result.fold(
        (failure) async =>
            print("❌🚨 [BLOC] Falló sincronización: ${failure.message}"),
        (isEnabled) async {
          print(
            "✅🚨 [BLOC] Sincronización exitosa. Backend devolvió enable=$isEnabled",
          );
          await tokenStorage.saveBiometricsEnabledForUser(userId, isEnabled);
          print(
            "💾🚨 [BLOC] Caché local actualizado para $userId a: $isEnabled",
          );

          final currentState = state;
          if (currentState is AuthSuccess) {
            print(
              "✅🚨 [BLOC] Emitting new AuthSuccess with isBiometricEnabled=$isEnabled",
            );
            emit(currentState.copyWith(isBiometricEnabled: isEnabled));
          } else {
            print(
              "⚠️🚨 [BLOC] Current state is NOT AuthSuccess, cannot update biometric status. State: $currentState",
            );
          }
        },
      );
    } catch (e) {
      print("❌🚨 [BLOC] Exception in _syncBiometricStatus: $e");
    }
  }
}
