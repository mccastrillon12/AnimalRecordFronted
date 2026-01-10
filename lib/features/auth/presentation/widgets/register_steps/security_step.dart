import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class SecurityStep extends StatelessWidget {
  final TextEditingController passwordController;

  const SecurityStep({super.key, required this.passwordController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Contraseña',
          isPassword: true,
          controller: passwordController,
        ),
        const SizedBox(height: 16),
        const CustomTextField(label: 'Confirmar contraseña', isPassword: true),
        const SizedBox(height: 24),
        Text('Debe contener:', style: AppTypography.body5),
        const SizedBox(height: 8),
        _buildRequirementItem('8 caracteres mínimo', true),
        _buildRequirementItem('1 minúscula y 1 mayúscula', true),
        _buildRequirementItem('1 número', false),
        _buildRequirementItem('1 carácter especial', false),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check : Icons.circle_outlined,
          size: 16,
          color: met ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.body6.copyWith(
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
