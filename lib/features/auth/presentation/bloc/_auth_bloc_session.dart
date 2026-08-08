part of 'auth_bloc.dart';

/// Shared session helpers used by login, security and profile handlers.
Future<void> _saveUserToCacheImpl(AuthBloc bloc, UserEntity user) async {
  await bloc.userCache.save(user);
}

Future<void> _emitAuthSuccessWithBiometricsImpl(
  AuthBloc bloc,
  UserEntity user,
  Emitter<AuthState> emit,
) async {
  await _syncBiometricStatusImpl(bloc, user.id, emit);
  final isEnabled = await bloc.tokenStorage.getBiometricsEnabledForUser(
    user.id,
  );
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
  } catch (_) {
    // Non-critical: biometric sync failure must not block the session.
  }
}
