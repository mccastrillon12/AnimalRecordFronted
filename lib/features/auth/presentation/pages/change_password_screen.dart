import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../../../../core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';

import 'package:animal_record/core/utils/password_validator.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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

    final isValidLogic = PasswordValidator.isValid(newPass);
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
    final canSubmit =
        _currentPasswordController.text.isNotEmpty &&
        _isNewPasswordValid &&
        _passwordsMatch;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordChangeSuccess) {
          ErrorDisplay.showSuccess(context, 'Contraseña cambiada con éxito.');
          Navigator.pop(context);
        } else if (state is AuthError) {
          ErrorDisplay.showError(
            context,
            'Error: ${state.message}. Por favor valide las contraseñas.',
          );
        } else if (state is AuthSuccess && state.updateError != null) {
          ErrorDisplay.showError(
            context,
            'Error: ${state.updateError}. Por favor valide las contraseñas.',
          );
        }
      },
      child: ModalPageLayout(
        title: 'Cambiar contraseña',
        bottomChild: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return CustomButton(
              text: 'Cambiar',
              isLoading:
                  state is AuthLoading ||
                  (state is AuthSuccess && state.isUpdating),
              onPressed:
                  canSubmit &&
                      state is! AuthLoading &&
                      !(state is AuthSuccess && state.isUpdating)
                  ? () {
                      context.read<AuthBloc>().add(
                        ChangePasswordRequested(
                          oldPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        ),
                      );
                    }
                  : null,
            );
          },
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.l),
              CustomTextField(
                controller: _currentPasswordController,
                label: 'Contraseña actual',
                isPassword: true,
                obscureText: _obscureCurrent,
                onToggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: AppSpacing.l),
              CustomTextField(
                controller: _newPasswordController,
                label: 'Nueva contraseña',
                isPassword: true,
                obscureText: _obscureNew,
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: AppSpacing.m),

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _newPasswordController,
                builder: (context, value, child) {
                  return PasswordRequirementsValidator(password: value.text);
                },
              ),

              const SizedBox(height: AppSpacing.l),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar nueva contraseña',
                isPassword: true,
                obscureText: _obscureConfirm,
                errorText: _confirmPasswordError,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: AppSpacing.l),
              const KeyboardSpacer(),
            ],
          ),
        ),
      ),
    );
  }
}
