import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'biometric_confirmation_screen.dart';

class BiometricActivationScreen extends StatefulWidget {
  const BiometricActivationScreen({super.key});

  @override
  State<BiometricActivationScreen> createState() =>
      _BiometricActivationScreenState();
}

class _BiometricActivationScreenState extends State<BiometricActivationScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _activateBiometrics() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          _showSnackBar('Tu dispositivo no soporta biometría', isError: true);
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Por favor autentícate para activar el ingreso biométrico',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        _showSnackBar('Biometría activada correctamente');
        // Marcar biometría como pendiente de asociación al usuario (se confirmará al hacer login)
        await sl<TokenStorage>().setBiometricActivationPending(true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BiometricConfirmationScreen(),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == auth_error.notAvailable) {
          _showSnackBar(
            'Biometría no disponible en este dispositivo',
            isError: true,
          );
        } else if (e.code == auth_error.notEnrolled) {
          _showSnackBar('No hay datos biométricos configurados', isError: true);
        } else {
          _showSnackBar('Error de autenticación: ${e.message}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Ocurrió un error inesperado', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.errorRojo
            : AppColors.successEsmeralda,
      ),
    );
  }

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
              // Icono biométrico grande
              SvgPicture.asset(
                iconPath,
                width: 120, // Ajustar tamaño según diseño
                height: 120,
                colorFilter: const ColorFilter.mode(
                  AppColors
                      .greyBlanco, // O el color que corresponda según diseño
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Título
              Text(
                'Activar biometría',
                textAlign: TextAlign.center,
                style: AppTypography.heading2.copyWith(
                  color: AppColors.primaryWhite,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // Descripción
              Text(
                'Habilita esta opción para que puedas ingresar de forma más rápida y segura usando la huella o el rostro registrado en tu dispositivo.',
                textAlign: TextAlign.center,
                style: AppTypography.body4.copyWith(
                  color: AppColors.primaryWhite,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Indicadores de página (Puntos)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFrances, // Azul activo
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greyMedio.withOpacity(
                        0.5,
                      ), // Gris inactivo
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botón Activar
              CustomButton(
                text: 'Activar',
                isLoading: _isAuthenticating,
                onPressed: _activateBiometrics,
              ),
              const SizedBox(height: AppSpacing.m),

              // Botón Cancelar
              CustomButton(
                text: 'Cancelar',
                isSecondary: true,
                onPressed: () {
                  if (!_isAuthenticating) {
                    Navigator.pop(context);
                  }
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
