import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/auth/presentation/widgets/auth_form_container.dart';
import 'package:flutter/material.dart';

class LinkExpiredScreen extends StatelessWidget {
  final bool isPinFlow;

  const LinkExpiredScreen({super.key, this.isPinFlow = false});

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: false,
      showCancelButton: false,
      onBack: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/illustrations/Source-02.png',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Este enlace ha expirado',
            style: AppTypography.heading1.copyWith(color: AppColors.greyNegro),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            isPinFlow
                ? 'El enlace para cambiar el PIN ha expirado, reintenta:'
                : 'El enlace para cambiar la contraseña ha expirado, reintenta:',
            style: AppTypography.body4.copyWith(color: AppColors.greyNegro),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          GestureDetector(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                isPinFlow ? '/forgot-pin' : '/forgot-password',
                (route) => false,
              );
            },
            child: Text(
              isPinFlow ? 'Cambiar PIN' : 'Cambiar contraseña',
              style: AppTypography.body3.copyWith(
                color: AppColors.primaryFrances,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
