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
    required this.logoutUseCase,
    required this.tokenStorage,
  }) : super(AuthInitial()) {
    on<FetchUserRequested>((event, emit) async {
      // 1. Try to load from cache
      final cachedUser = await tokenStorage.getUserData();
      if (cachedUser != null) {
        try {
          final userMap = json.decode(cachedUser);
          final user = UserModel.fromJson(userMap);

          // Only emit if we are not already in AuthSuccess with the same user
          final currentState = state;
          if (currentState is! AuthSuccess || currentState.user != user) {
            emit(AuthSuccess(user));
          }
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
              emit(AuthError(failure.message));
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
              emit(AuthSuccess(user));
            }
          },
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
          // Cache full user profile
          if (user is UserModel) {
            await tokenStorage.saveUserData(json.encode(user.toJson()));
          }
          emit(AuthSuccess(user));
        },
      );
    });

    on<VerifyCodeSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyCodeUseCase(event.params);

      await result.fold(
        (failure) async => emit(AuthError(failure.message)),
        (_) async => emit(VerificationSuccess()),
      );
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
  }
}
