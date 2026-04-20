import 'package:flutter/material.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/auth_form_container.dart';
import '../../../../core/widgets/utils/keyboard_spacer.dart';
import '../../../../core/widgets/inputs/pin_input_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:animal_record/features/auth/presentation/pages/forgot_pin_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/biometric_lock_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final String identifier;
  final bool bypassBiometric;

  const PinEntryScreen({
    super.key, 
    required this.identifier,
    this.bypassBiometric = false,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final FocusNode _focusNode = FocusNode();

  String _currentPin = '';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    setState(() {
      _currentPin = value;
    });
  }



  void _handleVerify() {
    if (_currentPin.length != 4) return;

    context.read<AuthBloc>().add(VerifyPinSubmitted(_currentPin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ErrorDisplay.showError(
            context,
            'PIN incorrecto. Intente nuevamente.',
          );
          setState(() {
            _currentPin = '';
            _focusNode.requestFocus();
          });
        }
        if (state is AuthSuccess) {
          if (state.pinVerifiedSuccess) {
            if (state.isBiometricEnabled && !widget.bypassBiometric) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BiometricLockScreen(),
                ),
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            }
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
              ),
              ],
            ),
            child: AuthFormContainer(
              showLogo: true,
              showCancelButton: false,
              onBack: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Ingresa tu PIN', style: AppTypography.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.identifier,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),

                  const SizedBox(height: 100),

                  PinInputField(
                    pin: _currentPin,
                    onChanged: _onCodeChanged,
                    focusNode: _focusNode,
                    obscureText: true,
                  ),

                  const SizedBox(height: 40),

                  CustomButton(
                    text: 'Ingresar',
                    isLoading: isLoading,
                    onPressed: isLoading || _currentPin.length != 4
                        ? null
                        : _handleVerify,
                  ),

                  const SizedBox(height: AppSpacing.l),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ForgotPinScreen(identifier: widget.identifier),
                        ),
                      );
                    },
                    child: Text(
                      '¿Olvidaste el PIN?',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.primaryFrances,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
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
