import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../widgets/auth_form_container.dart';

class CheckMessagesScreen extends StatelessWidget {
  final String email;

  const CheckMessagesScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showCancelButton: false,
      showLogo: false,
      onBack: () => Navigator.pop(context),
      addInternalPadding: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/illustrations/email.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Revisa tus mensajes',
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Si no encuentras las instrucciones, recuerda revisar la carpeta de correo no deseados. (En caso de correo electrónico) o verifica los mensajes SMS recientes. Si aún tienes inconvenientes intenta:',
                textAlign: TextAlign.center,
                style: AppTypography.body4,
              ),
              const SizedBox(height: AppSpacing.m),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: Text(
                  'Reenviar',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.primaryFrances,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
