import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';

class BiometricConfirmationScreen extends StatelessWidget {
  const BiometricConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final String iconPath = isIOS
        ? 'assets/icons/scan-face.svg'
        : 'assets/icons/fingerprint.svg';

    return Scaffold(
      backgroundColor: AppColors.primaryIndigo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            children: [
              const Spacer(),

              SvgPicture.asset(
                iconPath,
                width: 120,
                height: 120,
                colorFilter: const ColorFilter.mode(
                  AppColors.greyBlanco,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 98),

              Text(
                '¡Falta poco!',
                textAlign: TextAlign.center,
                style: AppTypography.heading1.copyWith(
                  color: AppColors.primaryWhite,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              Text(
                'Sólo falta iniciar sesión para asociar el Face ID o huella a tu cuenta.',
                textAlign: TextAlign.start,
                style: AppTypography.body4.copyWith(
                  color: AppColors.primaryWhite,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greyMedio.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFrances,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              CustomButton(
                text: 'Iniciar sesión',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(hideBiometrics: true),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.m),

              CustomButton(
                text: 'Cancelar',
                isSecondary: true,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
