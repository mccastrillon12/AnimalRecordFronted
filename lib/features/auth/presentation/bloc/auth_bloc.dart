import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/usecases/check_identification_exists_usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;
  final CheckIdentificationExistsUseCase checkIdentificationExistsUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.verifyCodeUseCase,
    required this.checkIdentificationExistsUseCase,
  }) : super(AuthInitial()) {
    on<SignUpSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await registerUseCase(event.userData);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthSuccess(user)),
      );
    });

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await loginUseCase(event.credentials);

      result.fold((failure) {
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
      }, (user) => emit(AuthSuccess(user)));
    });

    on<VerifyCodeSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyCodeUseCase(event.params);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(VerificationSuccess()),
      );
    });

    on<CheckIdentificationExists>((event, emit) async {
      emit(AuthLoading());

      final result = await checkIdentificationExistsUseCase(
        event.identificationNumber,
      );

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (exists) => emit(IdentificationCheckResult(exists)),
      );
    });
  }
}
