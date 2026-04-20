part of 'auth_bloc.dart';

/// SignUp, check identification, check availability, resend code handlers.

Future<void> _onSignUpSubmitted(
  AuthBloc bloc,
  SignUpSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.registerUseCase(event.userData);

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (user) async => emit(AuthSuccess(user)),
  );
}

Future<void> _onCheckIdentificationExists(
  AuthBloc bloc,
  CheckIdentificationExists event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.checkIdentificationExistsUseCase(
    event.identificationNumber,
  );

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (exists) async => emit(IdentificationCheckResult(exists)),
  );
}

Future<void> _onCheckAvailabilityRequested(
  AuthBloc bloc,
  CheckAvailabilityRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());

  final result = await bloc.checkAvailabilityUseCase(event.dataToCheck);

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (availabilityStatus) async => emit(AvailabilityCheckResult(availabilityStatus)),
  );
}

Future<void> _onResendCodeSubmitted(
  AuthBloc bloc,
  ResendCodeSubmitted event,
  Emitter<AuthState> emit,
) async {
  final result = await bloc.resendCodeUseCase(event.identifier);

  await result.fold(
    (failure) async => emit(AuthError(failure.message)),
    (_) async => emit(ResendCodeSuccess()),
  );
}
