import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/auth_form_container.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hasMinLength = false;
  bool _hasUpperLower = false;
  bool _hasSpecialChar = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final value = _passwordController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUpperLower = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])').hasMatch(value);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    });
  }

  bool get _isFormValid {
    return _hasMinLength &&
        _hasUpperLower &&
        _hasSpecialChar &&
        _passwordController.text == _confirmPasswordController.text &&
        _passwordController.text.isNotEmpty;
  }

  void _handleChangePassword() {
    if (_isFormValid) {
      // TODO: Implement password change logic
      // For now, just show success and navigate back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showCancelButton: true,
      title: 'Cambiar contraseña',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.l),
            CustomTextField(
              label: 'Nueva contraseña',
              hint: '• • • • • • • •',
              controller: _passwordController,
              labelStyle: AppTypography.body6,
              hintStyle: AppTypography.body4.copyWith(
                color: AppColors.greyMedio,
              ),
              borderColor: AppColors.greyMedio,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.greyMedio,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Usa al menos:', style: AppTypography.body6),
            const SizedBox(height: AppSpacing.xs),
            _buildValidationItem('8 caracteres', _hasMinLength),
            _buildValidationItem('Minúscula y mayúscula', _hasUpperLower),
            _buildValidationItem('1 carácter especial', _hasSpecialChar),
            const SizedBox(height: AppSpacing.l),
            CustomTextField(
              label: 'Confirmar nueva contraseña',
              hint: '• • • • • • • •',
              controller: _confirmPasswordController,
              labelStyle: AppTypography.body6,
              hintStyle: AppTypography.body4.copyWith(
                color: AppColors.greyMedio,
              ),
              borderColor: AppColors.greyMedio,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.greyMedio,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Cambiar',
              onPressed: _isFormValid ? _handleChangePassword : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : AppColors.greyMedio,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.body5.copyWith(
              color: isValid ? Colors.green : AppColors.greyMedio,
            ),
          ),
        ],
      ),
    );
  }
}
