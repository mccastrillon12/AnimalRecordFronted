import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
// Duplicate import removed
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Although we use custom validation mostly
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isNewPasswordValid = false;
  bool _passwordsMatch = false;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _currentPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Check requirements (reusing local check for button state, though visual validator shows details)
    final hasMinLength = newPass.length >= 8;
    final hasUpperLower =
        newPass.contains(RegExp(r'[a-z]')) &&
        newPass.contains(RegExp(r'[A-Z]'));
    final hasNumber = newPass.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = newPass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final isValidLogic =
        hasMinLength && hasUpperLower && hasNumber && hasSpecialChar;
    final match = newPass.isNotEmpty && newPass == confirmPass;

    setState(() {
      _isNewPasswordValid = isValidLogic;
      _passwordsMatch = match;

      if (confirmPass.isNotEmpty && newPass != confirmPass) {
        _confirmPasswordError = 'Las contraseñas no coinciden';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Can submit if: all fields filled, new password valid, passwords match
    final canSubmit =
        _currentPasswordController.text.isNotEmpty &&
        _isNewPasswordValid &&
        _passwordsMatch;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordChangeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña cambiada exitosamente'),
              backgroundColor: AppColors.successEsmeralda,
            ),
          );
          Navigator.pop(context);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${state.message}. Por favor valide las contraseñas.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is AuthSuccess && state.updateError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${state.updateError}. Por favor valide las contraseñas.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgOxford, // Match MyAccountScreen background
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // The White Card
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 100,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header (moved inside card, similar to MyAccount but specific to this screen)
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 80,
                                      bottom: 24,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cambiar contraseña',
                                        style: AppTypography.heading2.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 32,
                                    right: 24,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Cancelar',
                                            style: AppTypography.body3.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.close,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _currentPasswordController,
                                label: 'Contraseña actual',
                                isPassword: true,
                                obscureText: _obscureCurrent,
                                onToggleVisibility: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                              ),
                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _newPasswordController,
                                label: 'Nueva contraseña',
                                isPassword: true,
                                obscureText: _obscureNew,
                                onToggleVisibility: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                              const SizedBox(height: 16),

                              // Requirements Validator
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _newPasswordController,
                                builder: (context, value, child) {
                                  return PasswordRequirementsValidator(
                                    password: value.text,
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar nueva contraseña',
                                isPassword: true,
                                obscureText: _obscureConfirm,
                                errorText: _confirmPasswordError,
                                onToggleVisibility: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),

                              const Spacer(),

                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return CustomButton(
                                    text: 'Cambiar',
                                    isLoading:
                                        state is AuthLoading ||
                                        (state is AuthSuccess &&
                                            state.isUpdating),
                                    onPressed:
                                        canSubmit &&
                                            state is! AuthLoading &&
                                            !(state is AuthSuccess &&
                                                state.isUpdating)
                                        ? () {
                                            context.read<AuthBloc>().add(
                                              ChangePasswordRequested(
                                                oldPassword:
                                                    _currentPasswordController
                                                        .text,
                                                newPassword:
                                                    _newPasswordController.text,
                                              ),
                                            );
                                          }
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
