import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/register_cubit.dart';
import '../../cubit/register_state.dart';

class SecurityStep extends StatefulWidget {
  const SecurityStep({super.key});

  @override
  State<SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<SecurityStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Contraseña',
              isPassword: true,
              obscureText: _obscurePassword,
              initialValue: state.password.value,
              onChanged: cubit.passwordChanged,
              onToggleVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            const SizedBox(height: AppSpacing.m),
            PasswordRequirementsValidator(password: state.password.value),
            const SizedBox(height: AppSpacing.m),
            CustomTextField(
              label: 'Confirmar contraseña',
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              initialValue: state.confirmPassword.value,
              onChanged: cubit.confirmPasswordChanged,
              errorText: state.confirmPassword.value.isNotEmpty && state.password.value != state.confirmPassword.value 
                  ? 'Las contraseñas no coinciden' 
                  : null,
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
                    value: state.acceptTerms,
                    activeColor: AppColors.primaryFrances,
                    onChanged: (value) => cubit.acceptTermsChanged(value ?? false),
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
                            color: AppColors.primaryFrances,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryFrances,
                          ),
                        ),
                        const TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: AppTypography.body4.copyWith(
                            color: AppColors.primaryFrances,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryFrances,
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
      },
    );
  }
}
