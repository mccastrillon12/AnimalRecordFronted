part of 'auth_bloc.dart';

/// PIN, biometric, password change/reset/forgot/validate handlers.

Future<void> _onSavePinSubmitted(
  AuthBloc bloc,
  SavePinSubmitted event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
  UserEntity? currentUser;

  if (currentState is AuthSuccess) {
    currentUser = currentState.user;
  }

  emit(AuthLoading());

  final result = await bloc.savePinUseCase(event.pin);

  await result.fold(
    (failure) async {
      emit(AuthError(failure.message));
    },
    (_) async {
      if (currentUser != null && currentState is AuthSuccess) {
        final updatedUser = currentUser.copyWith(
          securityLastUpdated: DateTime.now().toUtc(),
        );
        await _saveUserToCacheImpl(bloc, updatedUser);
        bloc.add(FetchUserRequested());

        emit(
          AuthSuccess(
            updatedUser,
            pinSaveSuccess: true,
            isBiometricEnabled: currentState.isBiometricEnabled,
          ),
        );
      } else {
        bloc.add(FetchUserRequested());
      }
    },
  );
}

Future<void> _onVerifyPinSubmitted(
  AuthBloc bloc,
  VerifyPinSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.verifyPinUseCase(event.pin);

  await result.fold(
    (failure) async {
      emit(AuthError(failure.message));
    },
    (_) async {
      final userId = await bloc.tokenStorage.getUserId();
      if (userId != null) {
        final userResult = await bloc.getUserProfileUseCase(userId);
        await userResult.fold(
          (failure) async {
            bloc.add(FetchUserRequested());
          },
          (user) async {
            await _saveUserToCacheImpl(bloc, user);
            final isEnabled = await bloc.tokenStorage.getBiometricsEnabledForUser(
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
        bloc.add(FetchUserRequested());
      }
    },
  );
}

Future<void> _onChangePinRequested(
  AuthBloc bloc,
  ChangePinRequested event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
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

  final result = await bloc.changePinUseCase(event.oldPin, event.newPin);

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
      final updatedUser = currentState.user.copyWith(
        securityLastUpdated: DateTime.now().toUtc(),
      );
      await _saveUserToCacheImpl(bloc, updatedUser);
      bloc.add(FetchUserRequested());

      emit(
        AuthSuccess(
          updatedUser,
          isUpdating: false,
          pinChangeSuccess: true,
          isBiometricEnabled: currentState.isBiometricEnabled,
        ),
      );
    },
  );
}

Future<void> _onForgotPinRequested(
  AuthBloc bloc,
  ForgotPinRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.forgotPinUseCase(event.identifier);

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (_) async => emit(ForgotPinSuccess()),
  );
}

Future<void> _onResetPinSubmitted(
  AuthBloc bloc,
  ResetPinSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.resetPinUseCase(
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
  AuthBloc bloc,
  UpdateBiometricStatusRequested event,
  Emitter<AuthState> emit,
) async {
  final result = await bloc.updateBiometricStatusUseCase(event.enabled);

  await result.fold((failure) async => null, (_) async {
    final userId = await bloc.tokenStorage.getUserId();
    if (userId != null) {
      await bloc.tokenStorage.saveBiometricsEnabledForUser(userId, event.enabled);

      final currentState = bloc.state;
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
  AuthBloc bloc,
  SyncBiometricStatusRequested event,
  Emitter<AuthState> emit,
) async {
  final userId = await bloc.tokenStorage.getUserId();
  if (userId != null) {
    await _syncBiometricStatusImpl(bloc, userId, emit);
  }
}

Future<void> _onChangePasswordRequested(
  AuthBloc bloc,
  ChangePasswordRequested event,
  Emitter<AuthState> emit,
) async {
  final currentState = bloc.state;
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

  final result = await bloc.changePasswordUseCase(
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
        final updatedUser = currentUser.copyWith(
          securityLastUpdated: DateTime.now().toUtc(),
        );
        await _saveUserToCacheImpl(bloc, updatedUser);
        bloc.add(FetchUserRequested());

        emit(
          PasswordChangeSuccess(
            updatedUser,
            isBiometricEnabled: currentState is AuthSuccess
                ? currentState.isBiometricEnabled
                : false,
          ),
        );
      } else {
        bloc.add(FetchUserRequested());
        emit(PasswordChangeSuccess(UserModel.empty()));
      }
    },
  );
}

Future<void> _onResetPasswordSubmitted(
  AuthBloc bloc,
  ResetPasswordSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.resetPasswordUseCase(
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
  AuthBloc bloc,
  ValidateResetToken event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.validatePasswordTokenUseCase(
    event.identifier,
    event.token,
  );

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
  AuthBloc bloc,
  ForgotPasswordRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.forgotPasswordUseCase(event.identifier);

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (_) async => emit(ForgotPasswordSuccess()),
  );
}
