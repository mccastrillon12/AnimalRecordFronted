import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/auth_form_container.dart';
import '../../../../core/widgets/utils/keyboard_spacer.dart';

import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/utils/error_display.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _currentStep = 1; // 1: Crear, 2: Confirmar
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  String _firstPin = '';
  String _currentPin = '';
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Rebuild current PIN string
    final pin = _controllers.map((c) => c.text).join();

    setState(() {
      _currentPin = pin;
      _errorMessage = null; // Clear error on typing
    });

    // Auto-advance if logic desires, but user has a button
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Update current PIN to reflect the deletion
    final pin = _controllers.map((c) => c.text).join();
    setState(() {
      _currentPin = pin;
    });
  }

  void _handleContinue() {
    if (_currentPin.length != 4) return;

    if (_currentStep == 1) {
      // Move to step 2
      setState(() {
        _firstPin = _currentPin;
        _currentStep = 2;
        _currentPin = '';
        _errorMessage = null;
        // Clear fields for next step
        for (var c in _controllers) {
          c.clear();
        }
        // Focus first field again
        _focusNodes[0].requestFocus();
      });
    } else {
      if (_currentPin == _firstPin) {
        // Success
        // Dispatch event to save PIN to API
        context.read<AuthBloc>().add(SavePinSubmitted(_currentPin));
      } else {
        setState(() {
          _errorMessage = 'Los PIN no coinciden. Inténtalo de nuevo.';
          // Optionally clear fields or keep them? Usually clear.
          // Let's clear to force retry
          for (var c in _controllers) {
            c.clear();
          }
          _currentPin = '';
          _focusNodes[0].requestFocus();
          // Reset to step 1 often? Or simply retry confirmation?
          // Design says "Ingresa nuevamente". Usually if mismatch, we retry confirmation.
          // But if user forgot first PIN, they are stuck.
          // Usually we might just clear fields and let them try matching again.
          // If they fail too many times, maybe reset to step 1.
          // For now, retry confirmation step.
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStep1 = _currentStep == 1;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        debugPrint("📌 PinSetupScreen Listener: $state"); // LOG
        if (state is AuthError) {
          setState(() {
            _errorMessage = state.message;
          });
        }
        if (state is AuthSuccess && state.pinSaveSuccess) {
          debugPrint(
            "📌 AuthSuccess with pinSaveSuccess=true. Saving locally...",
          ); // LOG
          // Also save locally for offline support / fallback
          final userId = await sl<TokenStorage>().getUserId();
          if (userId != null) {
            await sl<TokenStorage>().saveUserPin(userId, _currentPin);
          }

          if (!mounted) {
            debugPrint("📌 Not mounted after save, aborting nav"); // LOG
            return;
          }

          debugPrint("📌 Navigating to /home"); // LOG

          // Always show PIN success
          if (context.mounted) {
            ErrorDisplay.showSuccess(context, 'PIN configurado correctamente');
          }

          // Check if biometric activation is pending or if we are in the flow that enables it
          final isBiometricPending = await sl<TokenStorage>()
              .isBiometricActivationPending();

          // We show the message if it was pending OR if this is the initial setup flow (which this screen seems to be for)
          // Since we are calling UpdateBiometricStatusRequested(true) below, we can assume we want to tell the user.
          // However, to be safe, let's stick to the pending flag BUT ALSO set it if it wasn't.
          // Or just show it. Given the user request, they WANT to see it.

          if (isBiometricPending) {
            // Clear pending status
            await sl<TokenStorage>().setBiometricActivationPending(false);
          }

          if (context.mounted) {
            ErrorDisplay.showSecondSuccess(
              context,
              'Biometría activada exitosamente',
            );
          }

          // Al finalizar la creación del PIN, activar biometría en el backend
          if (mounted) {
            context.read<AuthBloc>().add(UpdateBiometricStatusRequested(true));
          }

          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthFormContainer(
            showLogo: false,
            showCancelButton: false,
            onBack: () {
              if (_currentStep == 2) {
                setState(() {
                  _currentStep = 1;
                  _currentPin = '';
                  for (var c in _controllers) {
                    c.clear();
                  }
                });
              } else {
                Navigator.pop(context);
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    isStep1 ? 'Crear PIN' : 'Confirmar PIN',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$_currentStep de 2',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    isStep1
                        ? 'Hemos detectado que haz iniciado sesión con redes sociales, por lo que necesitaremos que crees un PIN de 4 números que servirá de respaldo en caso de no funcionar la biometría.'
                        : 'Ingresa nuevamente los 4 números de tu PIN para confirmar.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // PIN Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppTypography.heading2,
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.greyMedio,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryFrances,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _onBackspace(index);
                              } else {
                                _onCodeChanged(index, value);
                              }
                              setState(() {}); // refresh for button state
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      _errorMessage!,
                      style: AppTypography.body4.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 40),
                  CustomButton(
                    text: isStep1 ? 'Continuar' : 'Verificar',
                    isLoading: isLoading,
                    onPressed: isLoading || _currentPin.length != 4
                        ? null
                        : _handleContinue,
                  ),
                  const SizedBox(height: 20),
                  const KeyboardSpacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
