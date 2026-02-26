import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../pages/register_screen.dart';
import '../pages/password_screen.dart';
import 'social_register_completion_screen.dart';
import 'biometric_activation_screen.dart';
import '../widgets/biometric_disable_dialog.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'pin_setup_screen.dart';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:animal_record/core/services/microsoft_auth_service.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/services/apple_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final bool hideBiometrics;

  const LoginScreen({super.key, this.hideBiometrics = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  bool _isValidInput = false;
  bool _isNavigating = false;
  bool _isSocialLoading = false;

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
      ErrorDisplay.showError(context, 'Por favor ingresa tu correo o celular');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordScreen(identifier: identifier),
      ),
    );
  }

  final google_sign_in.GoogleSignIn _googleSignIn = google_sign_in.GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
  );

  Future<void> _handleGoogleSignIn() async {
    try {
      final google_sign_in.GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn();

      if (googleUser != null) {
        final google_sign_in.GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final String? idToken = googleAuth.idToken;

        if (idToken != null && mounted) {
          context.read<AuthBloc>().add(
            SocialAuthChecked(provider: 'GOOGLE', token: idToken),
          );
        }
      }
    } catch (error) {
      sl<Logger>().e('Google Sign-In failed: $error');
      if (mounted) {
        ErrorDisplay.showError(
          context,
          'Error al iniciar sesión con Google: $error',
        );
      }
    }
  }

  Future<void> _handleMicrosoftSignIn() async {
    try {
      final microsoftAuth = sl<MicrosoftAuthService>();
      final token = await microsoftAuth.signIn();

      if (token != null && mounted) {
        setState(() => _isSocialLoading = true);
        context.read<AuthBloc>().add(
          SocialAuthChecked(provider: 'MICROSOFT', token: token),
        );
      } else {
        if (mounted) setState(() => _isSocialLoading = false);
      }
    } catch (error) {
      if (mounted) setState(() => _isSocialLoading = false);
      sl<Logger>().e('Microsoft Sign-In failed: $error');
      if (mounted) {
        ErrorDisplay.showError(
          context,
          'Error al iniciar sesión con Microsoft',
        );
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final appleAuth = sl<AppleAuthService>();
      final credential = await appleAuth.signIn();

      if (credential != null && mounted) {
        final token = credential.identityToken;

        if (token != null) {
          setState(() => _isSocialLoading = true);
          context.read<AuthBloc>().add(
            SocialAuthChecked(provider: 'APPLE', token: token),
          );
        } else {
          sl<Logger>().e('Apple Sign-In failed: Identity Token is null');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _isSocialLoading = false);
      sl<Logger>().e('Apple Sign-In failed: $error');
      if (mounted) {
        ErrorDisplay.showError(context, 'Error al iniciar sesión con Apple');
      }
    }
  }

  Future<void> _navigateToRegistrationCompletion(
    Map<String, dynamic> response, {
    String providerName = 'Google',
  }) async {
    if (!mounted) return;

    final profile = response['profile'] as Map<String, dynamic>?;
    final preAuthToken = response['preAuthToken'] as String?;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SocialRegisterCompletionScreen(
              name: profile?['firstName'] ?? '',
              email: profile?['email'] ?? '',
              preAuthToken: preAuthToken ?? '',
              providerName: providerName,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (mounted) {
      setState(() => _isSocialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SocialAuthNeedRegister) {
          _navigateToRegistrationCompletion(
            state.response,
            providerName: state.provider,
          );
        } else if (state is AuthSuccess && !_isNavigating) {
          _isNavigating = true;

          if (widget.hideBiometrics) {
            final storage = sl<TokenStorage>();
            storage.isBiometricActivationPending().then((isPending) async {
              if (isPending) {
                final authMethod = state.user.authMethod.toLowerCase();
                final isDirectLoginUser =
                    authMethod == 'email' || authMethod == 'phone';

                if (isDirectLoginUser) {
                  if (mounted) {
                    context.read<AuthBloc>().add(
                      UpdateBiometricStatusRequested(true),
                    );
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } else {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(),
                      ),
                    );
                  }
                }
              }
            });
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else if (state is AuthError) {
          if (state.message.contains('¡Cuenta creada con éxito!')) {
            ErrorDisplay.showSuccess(context, state.message);
          } else {
            ErrorDisplay.showError(context, state.message);
          }
          if (_isSocialLoading) {
            setState(() => _isSocialLoading = false);
          }
        }
      },
      child: AuthFormContainer(
        addInternalPadding: false,
        showCancelButton: false,
        child: Stack(
          children: [
            SingleChildScrollView(
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
                        Text(
                          '¿No tienes una cuenta? ',
                          style: AppTypography.body4,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(
                                  role: 'PROPIETARIO_MASCOTA',
                                ),
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
                  if (!widget.hideBiometrics) ...[
                    Center(child: _BiometricButton()),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                        ),
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
                        onTap: _handleMicrosoftSignIn,
                      ),
                      const SizedBox(width: AppSpacing.socialButtonGap),
                      _SocialButton(
                        iconPath: 'assets/icons/Apple_icon.svg',
                        label: 'Apple',
                        onTap: _handleAppleSignIn,
                      ),
                    ],
                  ),
                  const KeyboardSpacer(),
                ],
              ),
            ),
            if (_isSocialLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  Future<void> _handleBiometricTap(BuildContext context) async {
    final storage = sl<TokenStorage>();
    final userId = await storage.getUserId();

    if (userId != null) {
      final isEnabled = await storage.getBiometricsEnabledForUser(userId);

      if (isEnabled) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => BiometricDisableDialog(
              onDisable: () {
                context.read<AuthBloc>().add(
                  UpdateBiometricStatusRequested(false),
                );
                ErrorDisplay.showSuccess(
                  context,
                  'Biometría desactivada exitosamente',
                );
              },
            ),
          );
        }
      } else {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BiometricActivationScreen(),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BiometricActivationScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final String iconPath = isIOS
        ? 'assets/icons/scan-face.svg'
        : 'assets/icons/fingerprint.svg';
    final String label = isIOS ? 'Ingresa con FaceID' : 'Ingresa con Biometria';

    return GestureDetector(
      onTap: () => _handleBiometricTap(context),
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
