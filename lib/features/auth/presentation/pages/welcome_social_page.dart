import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';

class WelcomeSocialPage extends StatelessWidget {
  final String userName;

  const WelcomeSocialPage({super.key, this.userName = 'Jhon Doe'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF1A2B4C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                Image.asset('assets/Logo/Logotipo_blanco.png', height: 80),
                const SizedBox(height: AppSpacing.xxl),

                Text(
                  '¡Bienvenido $userName!',
                  style: AppTypography.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Estamos complacidos de tenerte en este espacio.',
                  style: AppTypography.body4.copyWith(color: Colors.white),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'En AnimalRecord podrás encontrar todo lo que necesites relacionado a tus animales.',
                  style: AppTypography.body4.copyWith(color: Colors.white),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: AppSpacing.xl),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contarás con información de:',
                    style: AppTypography.body4.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                _buildFeatureItem('Historia clínica'),
                _buildFeatureItem('Carné de vacunación'),
                _buildFeatureItem('Agregar nuevos animales'),
                _buildFeatureItem('Agenda'),
                _buildFeatureItem('Transferencia de animales'),
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Y mucho más...',
                    style: AppTypography.body4.copyWith(color: Colors.white),
                  ),
                ),

                const Spacer(flex: 2),

                CustomButton(
                  text: 'Comenzar',
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.s),
          Text(text, style: AppTypography.body4.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
