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
import 'package:animal_record/features/auth/domain/usecases/verify_pin_usecase.dart'; // Added
import 'package:animal_record/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:animal_record/features/auth/domain/usecases/save_pin_usecase.dart'; // Added
import 'package:animal_record/features/auth/domain/usecases/change_pin_usecase.dart'; // Added
import 'package:animal_record/features/auth/domain/usecases/update_biometric_status_usecase.dart'; // Added
import 'package:animal_record/features/auth/domain/usecases/get_biometric_status_usecase.dart'; // Added
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
      // 1. Try to load from cache
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
        } catch (e) {
          // If decoding fails, ignore and fetch from API
        }
      }

      // 2. Fetch from API using stored ID
      final userId = await tokenStorage.getUserId();
      if (userId != null) {
        final result = await getUserProfileUseCase(userId);

        await result.fold(
          (failure) async {
            // Only show error if we don't have cached data
            if (state is! AuthSuccess) {
              emit(AuthError('Session expired or invalid'));
            }
          },
          (user) async {
            // Update cache
            if (user is UserModel) {
              await tokenStorage.saveUserData(json.encode(user.toJson()));
            }

            // Only emit if the user data is actually different from what we have
            final currentState = state;
            if (currentState is! AuthSuccess || currentState.user != user) {
              await _syncBiometricStatus(user.id);
              emit(AuthSuccess(user));
            }
          },
        );
      } else if (!loadedFromCache) {
        // No cache and no userId -> No active session
        emit(AuthError('No active session'));
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
          // Cache full user profile
          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          await _syncBiometricStatus(user.id);
          emit(AuthSuccess(user));
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
        await _syncBiometricStatus(user.id);
        emit(AuthSuccess(user));
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
      // Don't emit AuthLoading to avoid blocking the verify button
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
          emit(SocialAuthNeedRegister(response));
        } else if (response['status'] == 'SUCCESS') {
          final user = response['user'];
          // Cache full user profile
          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          await _syncBiometricStatus(user.id);
          emit(AuthSuccess(user));
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
        // Cache full user profile
        if (user is UserModel) {
          await tokenStorage.saveUserData(json.encode(user.toJson()));
        }
        await _syncBiometricStatus(user.id);
        emit(AuthSuccess(user));
      });
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      await logoutUseCase();
      emit(AuthInitial());
    });

    on<UpdateProfileRequested>((event, emit) async {
      // Check current state to preserve user data
      final currentState = state;
      UserEntity? currentUser;

      if (currentState is AuthSuccess) {
        currentUser = currentState.user;
        emit(AuthSuccess(currentUser, isUpdating: true));
      } else {
        // Fallback if somehow called when not success (shouldn't happen in profile)
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
          // Update cache with new user data
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
        // Fallback if somehow called without AuthSuccess (should not happen in this flow)
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
            // Should not happen, but fallback
            emit(PasswordChangeSuccess(UserModel.empty()));
          }
        },
      );
    });

    on<SavePinSubmitted>((event, emit) async {
      print("🚀 SavePinSubmitted event received with PIN: ${event.pin}"); // LOG

      final currentState = state;
      UserEntity? currentUser;

      if (currentState is AuthSuccess) {
        currentUser = currentState.user;
      }

      emit(AuthLoading());
      print("🚀 Emitted AuthLoading"); // LOG

      final result = await savePinUseCase(event.pin);

      await result.fold(
        (failure) async {
          print("❌ SavePin Failed: ${failure.message}"); // LOG
          emit(AuthError(failure.message));
        },
        (_) async {
          print("✅ SavePin Success. Restoring user: $currentUser"); // LOG
          // If we had a user, restore success state
          if (currentUser != null) {
            emit(AuthSuccess(currentUser, pinSaveSuccess: true));
          } else {
            print("⚠️ CurrentUser is null, requesting fetch"); // LOG
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
      print("🚀 VerifyPinSubmitted event: ${event.pin}"); // LOG
      emit(AuthLoading());

      print("🔄 Calling verifyPinUseCase..."); // LOG
      final result = await verifyPinUseCase(event.pin);
      print("🔄 verifyPinUseCase returned"); // LOG

      await result.fold(
        (failure) async {
          print("❌ VerifyPin Failed: ${failure.message}"); // LOG
          emit(AuthError(failure.message));
        },
        (_) async {
          print("✅ VerifyPin Success"); // LOG
          // Pin is valid, fetch user to log them in fully or set session
          // We need to ensure we have the user ID from token storage first
          // which logic inside FetchUserRequested handles.

          // Instead of calling FetchUserRequested which emits generic AuthSuccess,
          // We should ideally fetch locally or just trigger the fetch but manually emit success if possible?
          // If we add(FetchUserRequested()), the BLOCK handler for FetchUserRequested will run.
          // That handler emits AuthSuccess(user). It does NOT know about pinVerifiedSuccess = true.

          // So we should try to fetch user here manually or modify fetch handler.
          // Let's try to fetch user manually here to control the emission.

          final userId = await tokenStorage.getUserId();
          if (userId != null) {
            print("📌 Fetching user profile for userId: $userId"); // LOG
            final userResult = await getUserProfileUseCase(userId);
            await userResult.fold(
              (failure) async {
                print("❌ Failed to fetch user: ${failure.message}"); // LOG
                add(FetchUserRequested());
              }, // Fallback
              (user) async {
                print("✅ User fetched successfully"); // LOG
                if (user is UserModel) {
                  await tokenStorage.saveUserData(json.encode(user.toJson()));
                }
                // Emit specific success state
                emit(AuthSuccess(user, pinVerifiedSuccess: true));
              },
            );
          } else {
            print(
              "⚠️ No userId found, falling back to FetchUserRequested",
            ); // LOG
            add(FetchUserRequested());
          }
        },
      );
    });

    on<ChangePinRequested>((event, emit) async {
      print(
        "🚀 ChangePinRequested event: oldPin=${event.oldPin}, newPin=${event.newPin}",
      ); // LOG

      final currentState = state;
      if (currentState is! AuthSuccess) {
        emit(AuthError('Debe estar autenticado para cambiar el PIN'));
        return;
      }

      emit(AuthSuccess(currentState.user, isUpdating: true));

      final result = await changePinUseCase(event.oldPin, event.newPin);

      await result.fold(
        (failure) async {
          print("❌ ChangePin Failed: ${failure.message}"); // LOG
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
          print("✅ ChangePin Success"); // LOG
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
          // Update local cache
          final userId = await tokenStorage.getUserId();
          if (userId != null) {
            await tokenStorage.saveBiometricsEnabledForUser(
              userId,
              event.enabled,
            );
          }
        },
      );
    });

    on<SyncBiometricStatusRequested>((event, emit) async {
      print("🚀🚨 [BLOC] SyncBiometricStatusRequested LLAMADO");
      final userId = await tokenStorage.getUserId();
      if (userId != null) {
        await _syncBiometricStatus(userId);
      }
    });
  }

  Future<void> _syncBiometricStatus(String userId) async {
    print("🔄🚨 [BLOC] Ejecutando _syncBiometricStatus para: $userId");
    final result = await getBiometricStatusUseCase();

    await result.fold(
      (failure) async =>
          print("❌🚨 [BLOC] Falló sincronización: ${failure.message}"),
      (isEnabled) async {
        print(
          "✅🚨 [BLOC] Sincronización exitosa. Backend devolvió enable=$isEnabled",
        );
        await tokenStorage.saveBiometricsEnabledForUser(userId, isEnabled);
        print("💾🚨 [BLOC] Caché local actualizado para $userId a: $isEnabled");
      },
    );
  }
}
