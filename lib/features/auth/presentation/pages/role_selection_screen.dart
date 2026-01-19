import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: false,
      onCancel: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige un perfil para comenzar',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _buildRoleCard(
              context,
              title: 'Veterinario',
              icon: Icons.medical_services_outlined,
              onTap: () => _navigateToRegister(context, 'VETERINARIO'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'Propietario',
              icon: Icons.pets_outlined,
              onTap: () => _navigateToRegister(context, 'PROPIETARIO_MASCOTA'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'Estudiante',
              icon: Icons.school_outlined,
              onTap: () => _showComingSoon(context, 'Estudiante'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'Laboratorio',
              icon: Icons.science_outlined,
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
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 110,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgHielo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.heading2)),
            // Placeholder para ilustración
            Icon(
              icon,
              size: 60,
              color: AppColors.secondaryCoral.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
