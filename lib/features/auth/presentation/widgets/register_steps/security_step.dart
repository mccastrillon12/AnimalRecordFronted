import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class SecurityStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool acceptTerms;
  final ValueChanged<bool> onTermsChanged;
  final String? confirmPasswordError;

  const SecurityStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.acceptTerms,
    required this.onTermsChanged,
    this.confirmPasswordError,
  });

  @override
  State<SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<SecurityStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
        const SizedBox(height: AppSpacing.m),

        // Using reusable PasswordRequirementsValidator component
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.passwordController,
          builder: (context, value, child) {
            return PasswordRequirementsValidator(password: value.text);
          },
        ),

        const SizedBox(height: AppSpacing.m),
        CustomTextField(
          label: 'Confirmar contraseña',
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          controller: widget.confirmPasswordController,
          errorText: widget.confirmPasswordError,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 22,
              width: 22,
              child: Checkbox(
                value: widget.acceptTerms,
                onChanged: (value) => widget.onTermsChanged(value ?? false),
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
                    color: AppColors.greyNegroV2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Términos de servicio',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.primaryAzulClaro,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryAzulClaro,
                      ),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de privacidad',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.primaryAzulClaro,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryAzulClaro,
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
