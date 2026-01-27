import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../pages/register_screen.dart';
import '../pages/password_screen.dart';
import 'social_register_completion_screen.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  bool _isValidInput = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _identifierController.removeListener(_validateInput);
    _identifierController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final value = _identifierController.text.trim();
    setState(() {
      _isValidInput = _isValidEmail(value) || _isValidPhone(value);
    });
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  bool _isValidPhone(String value) {
    if (value.isEmpty) return false;
    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    return phoneRegex.hasMatch(value);
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

  // ... (inside class)

  final google_sign_in.GoogleSignIn _googleSignIn =
      google_sign_in.GoogleSignIn();

  Future<void> _handleGoogleSignIn() async {
    // Note: un-focusing can cause a layout shift that contributes to blinking
    // when native dialogs open. Skipping for now as per user report.

    try {
      final google_sign_in.GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn();

      if (googleUser != null) {
        print('Signed in as: ${googleUser.email}');

        if (mounted) {
          // Use PageRouteBuilder for an instant transition, avoiding the
          // Flutter "slide" animation that can overlap with the Android resume.
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  SocialRegisterCompletionScreen(
                    name: googleUser.displayName ?? '',
                    email: googleUser.email,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      }
    } catch (error) {
      print('Google Sign-In failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión con Google: $error')),
        );
      }
    }
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
                          builder: (context) =>
                              const RegisterScreen(role: 'PROPIETARIO_MASCOTA'),
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
                keyboardType: TextInputType.emailAddress,
                maxLength: 50,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: CustomButton(
                text: 'Continuar',
                onPressed: _isValidInput ? _handleContinue : null,
              ),
            ),
            Center(child: _BiometricButton()),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: Text(
                    'O ingresa con',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyNegroV2,
                      height: 1.49,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  iconPath: 'assets/icons/Google_icon.svg',
                  label: 'Google',
                  onTap: _handleGoogleSignIn,
                ),
                const SizedBox(width: AppSpacing.socialButtonGap),
                _SocialButton(
                  iconPath: 'assets/icons/Microsoft_icon.svg',
                  label: 'Microsoft',
                ),
                const SizedBox(width: AppSpacing.socialButtonGap),
                _SocialButton(
                  iconPath: 'assets/icons/Apple_icon.svg',
                  label: 'Apple',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final String iconPath = isIOS
        ? 'assets/icons/scan-face.svg'
        : 'assets/icons/fingerprint.svg';
    final String label = isIOS ? 'Ingresa con FaceID' : 'Ingresa con Biometria';

    return GestureDetector(
      onTap: () {
        // TODO: Implementar autenticación biométrica
      },
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xxl,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.greyIconosBackground,
                borderRadius: AppBorders.medium(),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
                colorFilter: ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body6.copyWith(color: AppColors.greyNegroV2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.iconPath,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: AppSpacing.socialButtonSize,
            height: AppSpacing.socialButtonSize,
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.greyIconosBackground,
              border: Border.all(color: AppColors.border),
              borderRadius: AppBorders.medium(),
            ),
            child: SvgPicture.asset(
              iconPath,
              width: AppSpacing.iconSizeSmall,
              height: AppSpacing.iconSizeSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.body6.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
