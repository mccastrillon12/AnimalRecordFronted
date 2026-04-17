import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/auth/presentation/pages/biometric_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/services/deep_link_service.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Try to consume a cold-start deep link immediately when the navigator
      // is first available. If handled, skip the normal auth flow.
      final handled = await DeepLinkService().consumePendingLink(navigatorKey);
      if (!handled) {
        if (mounted) {
          context.read<AuthBloc>().add(FetchUserRequested());
        }
      } else {
        if (mounted) {
          setState(() {
            _hasNavigated = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_hasNavigated) return;

        if (state is AuthSuccess) {
          sl<TokenStorage>().getBiometricsEnabledForUser(state.user.id).then((
            enabled,
          ) async {
            if (mounted && !_hasNavigated) {
              // If a deep link is pending (e.g. reset-password cold start),
              // let DeepLinkService handle navigation and skip the normal flow.
              final handled = await DeepLinkService().consumePendingLink(navigatorKey);
              if (!handled) {
                if (mounted) {
                  setState(() => _hasNavigated = true);
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
              } else {
                if (mounted) {
                  setState(() => _hasNavigated = true);
                }
              }
            }
          });
        } else if (state is AuthError || state is AuthUnauthenticated) {
          if (!_hasNavigated) {
            // If a deep link is pending, handle it instead of showing login.
            DeepLinkService().consumePendingLink(navigatorKey).then((handled) {
              if (!handled) {
                if (mounted) {
                  setState(() => _hasNavigated = true);
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else {
                if (mounted) {
                  setState(() => _hasNavigated = true);
                }
              }
            });
          }
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundDegradeFull,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Logo/Logotipo_blanco.png', height: 80),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }
}
