import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/auth/presentation/widgets/auth_form_container.dart';
import 'package:flutter/material.dart';

class LinkExpiredScreen extends StatelessWidget {
  const LinkExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: false,
      showCancelButton: false,
      onBack: () => Navigator.pop(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/illustrations/Source-02.png',
            height:
                200, // Adjust height as needed based on the image aspect ratio
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Este enlace ha expirado',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'El enlace para cambiar la contraseña ha expirado, reintenta:',
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          GestureDetector(
            onTap: () {
              // Navigate to Login to restart the process
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/forgot-password',
                (route) => false,
              );
            },
            child: Text(
              'Cambiar contraseña',
              style: AppTypography.body1.copyWith(
                color: AppColors.primaryFrances,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
