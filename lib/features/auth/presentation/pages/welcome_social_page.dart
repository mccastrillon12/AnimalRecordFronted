import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/fixed_bottom_action_layout.dart';
import 'package:animal_record/core/utils/string_formatters.dart';

class WelcomeSocialPage extends StatelessWidget {
  final String userName;

  const WelcomeSocialPage({super.key, this.userName = 'Jhon Doe'});

  @override
  Widget build(BuildContext context) {
    final formattedName = StringFormatters.formatName(userName);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/illustrations/Fondo_Marca_ agua.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: FixedBottomActionLayout(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            bottomChild: CustomButton(
              text: 'Comenzar',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 84),

                  Center(
                    child: Image.asset(
                      'assets/Logo/Logotipo_blanco.png',
                      height: 85,
                    ),
                  ),
                  const SizedBox(height: 70),

                  Column(
                    children: [
                      Center(
                        child: Text(
                          '$formattedName, acabas de crear tu perfil',
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'PROPIETARIO',
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'En este perfil podrás encontrar todo lo que necesites relacionado a tus animales.',
                    style: AppTypography.body4.copyWith(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Contarás con información de:',
                    style: AppTypography.body4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  _buildFeatureItem('Historia clínica'),
                  _buildFeatureItem('Carné de vacunación'),
                  _buildFeatureItem('Agregar nuevos animales'),
                  _buildFeatureItem('Agenda'),
                  _buildFeatureItem('Transferencia de animales'),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Y mucho más...',
                    style: AppTypography.body4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
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
          const Icon(Icons.check, color: Color(0xFF67C1FF), size: 20),
          const SizedBox(width: AppSpacing.s),
          Text(text, style: AppTypography.body4.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
