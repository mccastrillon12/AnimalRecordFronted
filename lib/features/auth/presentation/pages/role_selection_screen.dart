import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: false,
      onCancel: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige un perfil para comenzar',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            _buildRoleCard(
              context,
              title: 'Veterinario',
              imageAsset: 'assets/illustrations/Perfil_veterinario.png',
              onTap: () => _navigateToRegister(context, 'VETERINARIO'),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildRoleCard(
              context,
              title: 'Propietario',
              imageAsset: 'assets/illustrations/Perfil_tutor.png',
              onTap: () => _navigateToRegister(context, 'PROPIETARIO_MASCOTA'),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildRoleCard(
              context,
              title: 'Estudiante',
              imageAsset: 'assets/illustrations/Perfil_estudiante.png',
              onTap: () => _showComingSoon(context, 'Estudiante'),
            ),
            const SizedBox(height: AppSpacing.m),
            _buildRoleCard(
              context,
              title: 'Laboratorio',
              imageAsset: 'assets/illustrations/Perfil_laboratorio.png',
              onTap: () => _showComingSoon(context, 'Laboratorio'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
    );
  }

  void _showComingSoon(BuildContext context, String role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('El registro para $role estará disponible próximamente'),
        backgroundColor: AppColors.primaryFrances,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgHielo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 26),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(title, style: AppTypography.body3),
              ),
            ),
            const Spacer(),
            // Wrap SVG in RepaintBoundary for better performance
            Padding(
              padding: const EdgeInsets.only(right: 24, top: 16, bottom: 16),
              child: Image.asset(
                imageAsset,
                width: 120,
                height: 85.26,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
