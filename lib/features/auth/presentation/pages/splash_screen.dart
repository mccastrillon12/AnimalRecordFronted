import 'package:animal_record/features/auth/presentation/pages/biometric_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch check session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(FetchUserRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // User authenticated - check biometric preference
          sl<TokenStorage>().getBiometricsEnabledForUser(state.user.id).then((
            enabled,
          ) {
            if (mounted) {
              if (enabled) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BiometricLockScreen(),
                  ),
                );
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            }
          });
        } else if (state is AuthError) {
          // No session or error - go to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF539DF3), // Light Blue
                Color(0xFF132D53), // Dark Blue
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Logo/Logotipo_blanco.png', height: 80),
              const SizedBox(height: 16),
              // We could add a loading indicator here if needed
              // const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
