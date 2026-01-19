import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../pages/role_selection_screen.dart';
import '../pages/password_screen.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu correo o celular')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordScreen(identifier: identifier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showCancelButton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Text(
                'Bienvenido a AnimalRecord',
                style: AppTypography.heading1,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes una cuenta? ', style: AppTypography.body4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Crear cuenta',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.primaryFrances,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxxl),
              child: Text(
                'Inicia con el correo o celular que definiste como método de ingreso en el momento del registro.',
                textAlign: TextAlign.start,
                style: AppTypography.body4,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.m),
              child: CustomTextField(
                label: 'Correo electrónico o celular',
                hint: 'Correo / Celular',
                controller: _identifierController,
                labelStyle: AppTypography.body6,
                hintStyle: AppTypography.body4.copyWith(
                  color: AppColors.greyMedio,
                ),
                borderColor: AppColors.greyMedio,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: CustomButton(
                text: 'Continuar',
                onPressed: _handleContinue,
              ),
            ),
            const SizedBox(height: 36), // Diseñado específicamente a 36px
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.filter_center_focus_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ingresa con FaceID',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: Text(
                    'O ingresa con',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialButton(icon: Icons.g_mobiledata, label: 'Google'),
                _SocialButton(icon: Icons.window, label: 'Microsoft'),
                _SocialButton(icon: Icons.apple, label: 'Apple'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: AppColors.primaryDark),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.body6.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
