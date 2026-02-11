import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:animate_do/animate_do.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'dart:convert';
import 'package:animal_record/features/auth/presentation/pages/login_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/password_screen.dart';
import 'package:animal_record/features/auth/presentation/pages/pin_entry_screen.dart';
import 'package:animal_record/core/utils/error_display.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  String _userName = '';
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _loadUserName();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _authMethod = 'EMAIL';
  String _userIdentifier = '';

  Future<void> _loadUserName() async {
    final userData = await sl<TokenStorage>().getUserData();
    if (userData != null) {
      try {
        final Map<String, dynamic> userMap = json.decode(userData);
        setState(() {
          _userName = userMap['name'] ?? '';
          _authMethod = userMap['authMethod'] ?? 'EMAIL';
          // Use email as identifier, or phone if email is missing (though model prioritizes email usually)
          _userIdentifier = userMap['email'] ?? userMap['cellPhone'] ?? '';
        });
      } catch (_) {}
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Por favor autentícate para acceder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        if (mounted) {
          ErrorDisplay.showError(context, 'Biometría no disponible');
        }
      }
    }
  }

  void _goToLogin() {
    // If standard auth (Email/Phone), go to Password Screen
    if (_authMethod == 'EMAIL' || _authMethod == 'PHONE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(identifier: _userIdentifier),
        ),
      );
    } else {
      // If Social Auth (Google, etc.), go to PIN Entry Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinEntryScreen(identifier: _userIdentifier),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF539DF3), // Light Blue
              Color(0xFF132D53), // Dark Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: FadeTransition(
              opacity: _opacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      SvgPicture.asset(
                        'assets/Logo/Imagotipo_blanco.png',
                        height: 60,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'ANIMAL RECORD',
                        style: AppTypography.heading1.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  if (_userName.isNotEmpty)
                    Text(
                      _userName,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.l),

                  Text(
                    'Tu cuenta sigue activa y tu información está segura con nosotros.\nIngresa con tu huella, FaceID o contraseña.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body4.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),

                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF774F), // Orange
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isIOS ? Icons.face : Icons.fingerprint),
                            const SizedBox(width: 8),
                            Text(
                              isIOS
                                  ? 'Ingresar con FaceID'
                                  : 'Ingresar con Biometría',
                              style: AppTypography.body1.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryIndigo,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ingresa con contraseña o PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
