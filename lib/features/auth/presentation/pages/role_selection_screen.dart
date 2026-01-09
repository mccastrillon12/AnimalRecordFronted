import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/theme/app_colors.dart';
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
            const Text(
              'Elige un perfil para comenzar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
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
              onTap: () => _navigateToRegister(context, 'ESTUDIANTE'),
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              title: 'Laboratorio',
              icon: Icons.science_outlined,
              onTap: () => _navigateToRegister(context, 'LABORATORIO'),
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
          color: const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            // Placeholder para ilustración
            Icon(
              icon,
              size: 60,
              color: AppColors.accentOrange.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
