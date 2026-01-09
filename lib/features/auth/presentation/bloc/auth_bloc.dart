import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_usecase.dart';
// ... otros imports

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;

  AuthBloc({required this.registerUseCase}) : super(AuthInitial()) {
    on<SignUpSubmitted>((event, emit) async {
      emit(AuthLoading()); // Indicamos a la UI que estamos trabajando
      try {
        final user = await registerUseCase(event.userData);
        emit(AuthSuccess(user)); // ¡Usuario creado con éxito!
      } catch (e) {
        emit(AuthError("No se pudo registrar: ${e.toString()}"));
      }
    });
  }
}
