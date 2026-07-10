import 'package:flutter/material.dart';
import 'package:animal_record/core/constants/app_routes.dart';
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
import 'package:keyboard_actions/keyboard_actions.dart';
import '../../../../core/widgets/inputs/pin_input_field.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _currentStep = 1;
  final FocusNode _focusNode = FocusNode();

  String _firstPin = '';
  String _currentPin = '';
  String? _errorMessage;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    setState(() {
      _currentPin = value;
      _errorMessage = null;
    });
  }

  void _handleContinue() {
    if (_currentPin.length != 4) return;

    if (_currentStep == 1) {
      setState(() {
        _firstPin = _currentPin;
        _currentStep = 2;
        _currentPin = '';
        _errorMessage = null;

        _focusNode.requestFocus();
      });
    } else {
      if (_currentPin == _firstPin) {
        context.read<AuthBloc>().add(SavePinSubmitted(_currentPin));
      } else {
        setState(() {
          _errorMessage = 'Los PIN no coinciden. Inténtalo de nuevo.';

          _currentPin = '';
          _focusNode.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStep1 = _currentStep == 1;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        debugPrint("📌 PinSetupScreen Listener: $state");
        if (state is AuthError) {
          setState(() {
            _errorMessage = state.message;
          });
        }
        if (state is AuthSuccess && state.pinSaveSuccess) {
          debugPrint(
            "📌 AuthSuccess with pinSaveSuccess=true. Saving locally...",
          );

          final userId = await sl<TokenStorage>().getUserId();
          if (userId != null) {
            await sl<TokenStorage>().saveUserPin(userId, _currentPin);
          }

          if (!mounted) {
            debugPrint("📌 Not mounted after save, aborting nav");
            return;
          }

          debugPrint("📌 Navigating to /home");

          if (context.mounted) {
            ErrorDisplay.showSuccess(context, 'PIN configurado correctamente');
          }

          final isBiometricPending = await sl<TokenStorage>()
              .isBiometricActivationPending();

          if (isBiometricPending) {
            await sl<TokenStorage>().setBiometricActivationPending(false);
            if (context.mounted) {
              ErrorDisplay.showSecondSuccess(
                context,
                'Biometría activada exitosamente',
              );
            }
            if (context.mounted) {
              context.read<AuthBloc>().add(
                UpdateBiometricStatusRequested(true),
              );
            }
          }

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return KeyboardActions(
            disableScroll: true,
            config: KeyboardActionsConfig(
              keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
              keyboardBarColor: const Color(0xFFD1D5DF),
              nextFocus: false,
              actions: [
                KeyboardActionsItem(
                  focusNode: _focusNode,
                  displayArrows: false,
                  displayDoneButton: false,
                  toolbarButtons: [
                  (node) {
                    return GestureDetector(
                      onTap: () => node.unfocus(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          "Aceptar",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                ],
              )
            ],
          ),
          child: AuthFormContainer(
            showLogo: false,
            showCancelButton: false,
            onBack: () async {
              if (_currentStep == 2) {
                setState(() {
                  _currentStep = 1;
                  _currentPin = '';
                });
              } else {
                final isBiometricPending = await sl<TokenStorage>()
                    .isBiometricActivationPending();
                if (isBiometricPending) {
                  await sl<TokenStorage>().setBiometricActivationPending(false);
                  if (context.mounted) {
                    context.read<AuthBloc>().add(LogoutRequested());
                    ErrorDisplay.showError(
                      context,
                      'Ha habido un error y no se ha podido registrar correctamente la Biometría, intente nuevamente.',
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                } else {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    isStep1 ? 'Crear PIN' : 'Confirmar PIN',
                    style: AppTypography.heading1,
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
                  const SizedBox(height: 80),

                  PinInputField(
                    pin: _currentPin,
                    onChanged: _onCodeChanged,
                    focusNode: _focusNode,
                    obscureText: true,
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      _errorMessage!,
                      style: AppTypography.body5.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
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
          ),
        );
      },
      ),
    );
  }
}
