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
import 'package:animal_record/features/auth/domain/usecases/validate_pin_token_usecase.dart';
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
  final ValidatePinTokenUseCase validatePinTokenUseCase;
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
    required this.checkSocialAuthUseCase,
    required this.registerSocialUseCase,
    required this.getUserProfileUseCase,
    required this.updateProfileUseCase,
    required this.changePasswordUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.validatePasswordTokenUseCase,
    required this.validatePinTokenUseCase,
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

    on<UpdateProfilePictureRequested>(_onUpdateProfilePicture);

    on<ClearAuthEvent>((event, emit) => emit(AuthInitial()));
  }

  Future<void> _onFetchUserRequested(
    FetchUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
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
      emit(AuthUnauthenticated());
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
        // El backend podría no devolver profilePicture en el endpoint de actualizar perfil.
        // Si el usuario resultante no tiene profilePicture, pero nosotros sí lo teníamos, lo preservamos.
        UserEntity finalUser = user;
        if (user.profilePicture == null &&
            currentUser != null &&
            currentUser.profilePicture != null) {
          finalUser = UserModel(
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
            profilePicture: currentUser.profilePicture,
          );
        }

        await _saveUserToCache(finalUser);
        emit(
          AuthSuccess(
            finalUser,
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
        // Inyectar nombres si fueron proveídos por el proveedor social (ej. Apple)
        // pero el backend no los tiene (porque no los enviamos en el check)
        if (event.firstName != null || event.lastName != null) {
          final profile =
              (response['profile'] as Map<String, dynamic>?) ?? {};
          profile['firstName'] = event.firstName ?? profile['firstName'];
          profile['lastName'] = event.lastName ?? profile['lastName'];
          
          // Crear campo 'name' combinado para compatibilidad con la UI
          final combinedName = '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
          if (combinedName.isNotEmpty) {
            profile['name'] = combinedName;
          }

          // Asegurar que el mapa de respuesta tenga el perfil actualizado
          final newResponse = Map<String, dynamic>.from(response);
          newResponse['profile'] = profile;

          emit(SocialAuthNeedRegister(newResponse, provider: event.provider));
          return;
        }

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
    
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async {
        // Si tenemos un nombre para actualizar (caso Apple), lo hacemos silenciosamente
        if (event.nameToUpdate != null && event.nameToUpdate!.isNotEmpty) {
          try {
            final updateResult = await updateProfileUseCase(
              id: user.id,
              data: {'name': event.nameToUpdate},
            );
            
            // Si la actualización tuvo éxito, usamos el nuevo usuario con el nombre corregido
            await updateResult.fold(
              (f) async {
                // Si falla el update, procedemos con el usuario original pero logueamos el error
                sl<Logger>().e('Error actualizando nombre post-registro social: ${f.message}');
                await _saveUserToCache(user);
                await _emitAuthSuccessWithBiometrics(user, emit);
              },
              (updatedUser) async {
                await _saveUserToCache(updatedUser);
                await _emitAuthSuccessWithBiometrics(updatedUser, emit);
              },
            );
            return;
          } catch (e) {
            sl<Logger>().e('Error inesperado actualizando nombre: $e');
          }
        }

        await _saveUserToCache(user);
        await _emitAuthSuccessWithBiometrics(user, emit);
      },
    );
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

    final result = event.isPinFlow
        ? await validatePinTokenUseCase(event.identifier, event.token)
        : await validatePasswordTokenUseCase(event.identifier, event.token);

    await result.fold(
      (failure) async {
        emit(ResetTokenInvalid());
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

  Future<void> _onUpdateProfilePicture(
    UpdateProfilePictureRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthSuccess) return;

    emit(
      currentState.copyWith(
        isUploadingPicture: true,
        profilePictureError: null,
      ),
    );

    try {
      // Paso 1: Comprimir imagen en el celular (sin gastar datos aún)
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        event.imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        emit(
          currentState.copyWith(
            isUploadingPicture: false,
            profilePictureError: 'No se pudo comprimir la imagen',
          ),
        );
        return;
      }

      const mimeType = 'image/jpeg';
      final fileSize = compressedBytes.length;

      // Paso 2: Obtener URL pre-firmada del backend
      final urlResult = await getProfilePictureUploadUrlUseCase(
        mimeType: mimeType,
        fileSize: fileSize,
      );

      await urlResult.fold(
        (failure) async {
          emit(
            currentState.copyWith(
              isUploadingPicture: false,
              profilePictureError: failure.message,
            ),
          );
        },
        (urlData) async {
          final uploadUrl = urlData['uploadUrl'] as String?;
          final finalUrl = urlData['finalUrl'] as String?;

          if (uploadUrl == null || finalUrl == null) {
            emit(
              currentState.copyWith(
                isUploadingPicture: false,
                profilePictureError: 'Respuesta inválida del servidor',
              ),
            );
            return;
          }

          // Paso 3: Subir directo a S3 (sin JWT, sin pasar por Lightsail)
          await s3UploadService.uploadFileToS3(
            presignedUrl: uploadUrl,
            bytes: compressedBytes,
            mimeType: mimeType,
          );

          // Paso 4: Confirmar al backend con la URL pública final
          final confirmResult = await confirmProfilePictureUseCase(finalUrl);

          await confirmResult.fold(
            (failure) async {
              emit(
                currentState.copyWith(
                  isUploadingPicture: false,
                  profilePictureError: failure.message,
                ),
              );
            },
            (_) async {
              // El backend a veces devuelve una respuesta parcial en el PATCH.
              // Para no perder los datos del usuario, clonamos el usuario actual
              // y le inyectamos la nueva URL de la foto:
              final oldUser = currentState.user;
              final accurateUser = UserModel(
                id: oldUser.id,
                name: oldUser.name,
                identificationType: oldUser.identificationType,
                identificationNumber: oldUser.identificationNumber,
                country: oldUser.country,
                countryId: oldUser.countryId,
                departmentId: oldUser.departmentId,
                city: oldUser.city,
                cityId: oldUser.cityId,
                address: oldUser.address,
                email: oldUser.email,
                cellPhone: oldUser.cellPhone,
                professionalCard: oldUser.professionalCard,
                animalTypes: oldUser.animalTypes,
                services: oldUser.services,
                isHomeDelivery: oldUser.isHomeDelivery,
                roles: oldUser.roles,
                authMethod: oldUser.authMethod,
                isVerified: oldUser.isVerified,
                profilePicture: finalUrl,
              );

              await _saveUserToCache(accurateUser);
              emit(
                AuthSuccess(
                  accurateUser,
                  isUploadingPicture: false,
                  isBiometricEnabled: currentState.isBiometricEnabled,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isUploadingPicture: false,
          profilePictureError: 'Error inesperado: ${e.toString()}',
        ),
      );
    }
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
