import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class PasswordRequirementsValidator extends StatelessWidget {
  final String password;
  final bool showTitle;

  const PasswordRequirementsValidator({
    super.key,
    required this.password,
    this.showTitle = true,
  });

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUpperLower =>
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get allRequirementsMet =>
      _hasMinLength && _hasUpperLower && _hasNumber && _hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Usa al menos:',
            style: AppTypography.body6.copyWith(color: AppColors.greyNegro),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        _buildRequirementItem('8 caracteres mínimo', _hasMinLength),
        const SizedBox(height: AppSpacing.xs),
        _buildRequirementItem('1 minúscula y 1 mayúscula', _hasUpperLower),
        const SizedBox(height: AppSpacing.xs),
        _buildRequirementItem('1 número', _hasNumber),
        const SizedBox(height: AppSpacing.xs),
        _buildRequirementItem('1 carácter especial', _hasSpecialChar),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          Icons.check,
          size: 16,
          color: met ? AppColors.successEsmeralda : AppColors.greyIconos,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: AppTypography.body6.copyWith(color: AppColors.greyIconos),
        ),
      ],
    );
  }
}
