part of 'auth_bloc.dart';

/// Login, social auth, verify code, fetch user and logout handlers.
extension _AuthBlocLogin on AuthBloc {
  // Handlers are accessed via the AuthBloc class using on<Event> registration.
  // This file only holds the method implementations.
}

Future<void> _onFetchUserRequested(
  AuthBloc bloc,
  FetchUserRequested event,
  Emitter<AuthState> emit,
) async {
  final cachedUser = await bloc.tokenStorage.getUserData();
  bool loadedFromCache = false;

  if (cachedUser != null) {
    try {
      final userMap = json.decode(cachedUser);
      final user = UserModel.fromJson(userMap);

      final currentState = bloc.state;
      if (currentState is! AuthSuccess || currentState.user != user) {
        emit(AuthSuccess(user));
      }
      loadedFromCache = true;
    } catch (e) {
      // Cache corrupted – ignore and fetch from API
    }
  }

  final userId = await bloc.tokenStorage.getUserId();
  if (userId != null) {
    final result = await bloc.getUserProfileUseCase(userId);

    await result.fold(
      (failure) async {
        if (bloc.state is! AuthSuccess) {
          emit(AuthError('Session expired or invalid'));
        }
      },
      (user) async {
        UserEntity finalUser = user;
        final currentState = bloc.state;
        
        if (currentState is AuthSuccess) {
          if (user.securityLastUpdated == null && currentState.user.securityLastUpdated != null) {
            finalUser = user.copyWith(securityLastUpdated: currentState.user.securityLastUpdated);
          }
        }

        await _saveUserToCacheImpl(bloc, finalUser);

        if (currentState is! AuthSuccess || currentState.user != finalUser) {
          await _emitAuthSuccessWithBiometricsImpl(bloc, finalUser, emit);
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

Future<void> _onLoginSubmitted(
  AuthBloc bloc,
  LoginSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.loginUseCase(event.credentials);

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
      await _saveUserToCacheImpl(bloc, user);
      await _emitAuthSuccessWithBiometricsImpl(bloc, user, emit);
    },
  );
}

Future<void> _onVerifyCodeSubmitted(
  AuthBloc bloc,
  VerifyCodeSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.verifyCodeUseCase(event.params);

  await result.fold((failure) async => emit(AuthError(failure.message)), (
    user,
  ) async {
    await _saveUserToCacheImpl(bloc, user);
    await _emitAuthSuccessWithBiometricsImpl(bloc, user, emit);
  });
}

Future<void> _onSocialAuthChecked(
  AuthBloc bloc,
  SocialAuthChecked event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.checkSocialAuthUseCase(
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
        final profile = (response['profile'] as Map<String, dynamic>?) ?? {};
        profile['firstName'] = event.firstName ?? profile['firstName'];
        profile['lastName'] = event.lastName ?? profile['lastName'];

        // Crear campo 'name' combinado para compatibilidad con la UI
        final combinedName =
            '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                .trim();
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
      await _saveUserToCacheImpl(bloc, user);
      await _emitAuthSuccessWithBiometricsImpl(bloc, user, emit);
    } else {
      emit(AuthError('Respuesta inesperada del servidor'));
    }
  });
}

Future<void> _onSocialRegisterSubmitted(
  AuthBloc bloc,
  SocialRegisterSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.registerSocialUseCase(event.data);

  await result.fold((failure) async => emit(AuthError(failure.message)), (
    user,
  ) async {
    // Si tenemos un nombre para actualizar (caso Apple), lo hacemos silenciosamente
    if (event.nameToUpdate != null && event.nameToUpdate!.isNotEmpty) {
      try {
        final updateResult = await bloc.updateProfileUseCase(
          id: user.id,
          data: {'name': event.nameToUpdate},
        );

        // Si la actualización tuvo éxito, usamos el nuevo usuario con el nombre corregido
        await updateResult.fold(
          (f) async {
            // Si falla el update, procedemos con el usuario original pero logueamos el error
            sl<Logger>().e(
              'Error actualizando nombre post-registro social: ${f.message}',
            );
            await _saveUserToCacheImpl(bloc, user);
            await _emitAuthSuccessWithBiometricsImpl(bloc, user, emit);
          },
          (updatedUser) async {
            await _saveUserToCacheImpl(bloc, updatedUser);
            await _emitAuthSuccessWithBiometricsImpl(bloc, updatedUser, emit);
          },
        );
        return;
      } catch (e) {
        sl<Logger>().e('Error inesperado actualizando nombre: $e');
      }
    }

    await _saveUserToCacheImpl(bloc, user);
    await _emitAuthSuccessWithBiometricsImpl(bloc, user, emit);
  });
}

Future<void> _onLogoutRequested(
  AuthBloc bloc,
  LogoutRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  // Reset animal data so the next user doesn't see the previous user's animals
  sl<AnimalCubit>().reset();

  // Limpiar sesiones sociales primero para forzar el selector de cuentas en el próximo login y evitar race conditions
  try {
    final googleSignIn = google_sign_in.GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    await googleSignIn.signOut();
  } catch (e) {
    sl<Logger>().w('Error al desconectar GoogleSignIn: $e');
  }

  try {
    final microsoftAuth = sl<MicrosoftAuthService>();
    await microsoftAuth.signOut();
  } catch (_) {}

  await bloc.logoutUseCase();

  emit(AuthInitial());
}
