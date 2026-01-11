import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class SecurityStep extends StatefulWidget {
  final TextEditingController passwordController;

  const SecurityStep({super.key, required this.passwordController});

  @override
  State<SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<SecurityStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  final TextEditingController _confirmController = TextEditingController();

  // Password requirements
  bool get _hasMinLength => widget.passwordController.text.length >= 8;
  bool get _hasUpperLower =>
      widget.passwordController.text.contains(RegExp(r'[a-z]')) &&
      widget.passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber =>
      widget.passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => widget.passwordController.text.contains(
    RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
  );

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_onPasswordChanged);
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Contraseña',
          isPassword: true,
          obscureText: _obscurePassword,
          controller: widget.passwordController,
          onToggleVisibility: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        const SizedBox(height: 24),
        Text('Debe contener:', style: AppTypography.body3),
        const SizedBox(height: 12),
        _buildRequirementItem('8 caracteres mínimo', _hasMinLength),
        const SizedBox(height: 8),
        _buildRequirementItem('1 minúscula y 1 mayúscula', _hasUpperLower),
        const SizedBox(height: 8),
        _buildRequirementItem('1 número', _hasNumber),
        const SizedBox(height: 8),
        _buildRequirementItem('1 carácter especial', _hasSpecialChar),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Confirmar contraseña',
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          controller: _confirmController,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) =>
                    setState(() => _acceptTerms = value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.greyMedio),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Acepto los ',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyNegro,
                  ),
                  children: [
                    TextSpan(
                      text: 'Términos de servicio',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.primaryAzulClaro,
                      ),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de privacidad',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.primaryAzulClaro,
                      ),
                    ),
                    const TextSpan(text: ' de Animal Record.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          Icons.check,
          size: 16,
          color: met ? AppColors.primaryFrances : AppColors.greyMedio,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.body4.copyWith(
            color: met ? AppColors.primaryFrances : AppColors.greyMedio,
          ),
        ),
      ],
    );
  }
}
