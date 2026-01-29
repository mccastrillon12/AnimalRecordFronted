import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOxford,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String name = 'Usuario';
          String email = '';
          String role = 'Propietario';

          if (state is AuthSuccess) {
            name = state.user.name;
            email = state.user.email;
            if (state.user.roles.isNotEmpty) {
              role = state.user.roles.first == 'PROPIETARIO_MASCOTA'
                  ? 'Propietario'
                  : state.user.roles.first;
            }
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        role,
                        style: AppTypography.body3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balancing back button
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.l),

                // Profile Section
                Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/default_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 60,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      name,
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      email,
                      style: AppTypography.body4.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.groups_outlined,
                        label: 'Cambiar perfil',
                        onTap: () {},
                      ),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Editar perfil',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Options Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        children: [
                          _buildOptionTile(
                            icon: Icons.person_outline,
                            label: 'Mi cuenta',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.notifications_none_outlined,
                            label: 'Notificaciones',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.translate_outlined,
                            label: 'Idiomas',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.fingerprint_outlined,
                            label: 'Ingreso con biometría',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.help_outline,
                            label: 'Centro de ayuda',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: Icons.gavel_outlined,
                            label: 'Términos y Políticas',
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildOptionTile(
                            icon: Icons.logout,
                            label: 'Cerrar sesión',
                            color: AppColors.secondaryCoral,
                            onTap: () {
                              context.read<AuthBloc>().add(LogoutRequested());
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Bottom Logo/Text as seen in images
                          Image.asset(
                            'assets/Logo/Imagotipo_azul.png',
                            height: 24,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ANIMAL RECORD',
                            style: AppTypography.body3.copyWith(
                              color: AppColors.primaryIndigo,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.body6.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final textColor = color ?? AppColors.greyTextos;
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: textColor),
          title: Text(
            label,
            style: AppTypography.body1.copyWith(color: textColor),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: color ?? AppColors.primaryFrances,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        Divider(color: AppColors.greyClaro, height: 1),
      ],
    );
  }
}
