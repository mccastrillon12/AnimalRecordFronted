import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/cards/selectable_role_card.dart';
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
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            SelectableRoleCard(
              title: 'Veterinario',
              imageAsset: 'assets/illustrations/Perfil_veterinario.png',
              onTap: () => _navigateToRegister(context, 'VETERINARIO'),
            ),
            const SizedBox(height: AppSpacing.m),
            SelectableRoleCard(
              title: 'Propietario',
              imageAsset: 'assets/illustrations/Perfil_tutor.png',
              onTap: () => _navigateToRegister(context, 'PROPIETARIO_MASCOTA'),
            ),
            const SizedBox(height: AppSpacing.m),
            SelectableRoleCard(
              title: 'Estudiante',
              imageAsset: 'assets/illustrations/Perfil_estudiante.png',
              onTap: () => _showComingSoon(context, 'Estudiante'),
            ),
            const SizedBox(height: AppSpacing.m),
            SelectableRoleCard(
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
}
