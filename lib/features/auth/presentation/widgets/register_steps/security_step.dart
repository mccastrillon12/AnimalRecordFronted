import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

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
        const SizedBox(height: AppSpacing.l),

        // Using reusable PasswordRequirementsValidator component
        PasswordRequirementsValidator(password: widget.passwordController.text),

        const SizedBox(height: AppSpacing.l),
        CustomTextField(
          label: 'Confirmar contraseña',
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          controller: _confirmController,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        const SizedBox(height: AppSpacing.l),
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
            const SizedBox(width: AppSpacing.s),
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
}
