import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'dart:convert';
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
          _userName = _capitalizeWords(userMap['name'] ?? '');
          _authMethod = userMap['authMethod'] ?? 'EMAIL';

          _userIdentifier = userMap['email'] ?? userMap['cellPhone'] ?? '';
        });
      } catch (_) {}
    }
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
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
    if (_authMethod == 'EMAIL' || _authMethod == 'PHONE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(identifier: _userIdentifier),
        ),
      );
    } else {
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
            colors: [Color(0xFF539DF3), Color(0xFF132D53)],
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
                      Image.asset(
                        'assets/Logo/Logotipo_blanco.png',
                        width: 296,
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  if (_userName.isNotEmpty)
                    Text(
                      _userName,
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.l),

                  Column(
                    children: [
                      Text(
                        'Tu cuenta sigue activa y tu información está \nsegura con nosotros.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body4.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa con tu huella, FaceID o contraseña.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF774F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isIOS ? Icons.face : Icons.fingerprint),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              isIOS
                                  ? 'Ingresar con FaceID'
                                  : 'Ingresar con Biometría',
                              style: AppTypography.body3.copyWith(
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
                          minimumSize: const Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Ingresa con contraseña o PIN',
                          style: AppTypography.body3.copyWith(
                            color: AppColors.primaryIndigo,
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
