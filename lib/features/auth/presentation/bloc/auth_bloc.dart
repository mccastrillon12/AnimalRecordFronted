import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.verifyCodeUseCase,
  }) : super(AuthInitial()) {
    on<SignUpSubmitted>((event, emit) async {
      print('=== SIGNUP STARTED ===');
      print('User Data: ${event.userData}');
      emit(AuthLoading());

      final result = await registerUseCase(event.userData);

      result.fold(
        (failure) {
          print('=== SIGNUP FAILED ===');
          print('Error: ${failure.message}');
          emit(AuthError(failure.message));
        },
        (user) {
          print('=== SIGNUP SUCCESS ===');
          print('User: $user');
          emit(AuthSuccess(user));
        },
      );
    });

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await loginUseCase(event.credentials);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(AuthSuccess(user)),
      );
    });

    on<VerifyCodeSubmitted>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyCodeUseCase(event.params);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(VerificationSuccess()),
      );
    });
  }
}
