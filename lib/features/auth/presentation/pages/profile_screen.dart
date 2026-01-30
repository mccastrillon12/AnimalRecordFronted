import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 0, 0),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Profile Section
                  Column(
                    children: [
                      Text(
                        role,
                        style: AppTypography.body3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryIndigo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(name),
                            style: AppTypography.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        height: 30,
                        alignment: Alignment.center,
                        child: Text(
                          _formatName(name),
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        height: 21,
                        alignment: Alignment.center,
                        child: Text(
                          email,
                          style: AppTypography.body4.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
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
                          icon: 'assets/icons/Edit.svg',
                          label: 'Editar perfil',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Options Card
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildOptionTile(
                            icon: Icons.person_outline,
                            label: 'Mi cuenta',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.greyClaro, height: 1),
                          _buildOptionTile(
                            icon: 'assets/icons/notification.svg',
                            label: 'Notificaciones',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: 'assets/icons/Language.svg',
                            label: 'Idiomas',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: 'assets/icons/scan-eye.svg',
                            label: 'Ingreso con biometría',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.greyClaro, height: 1),
                          _buildOptionTile(
                            icon: 'assets/icons/Help.svg',
                            label: 'Centro de ayuda',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            icon: 'assets/icons/Terms.svg',
                            label: 'Términos y Políticas',
                            onTap: () {},
                          ),

                          _buildOptionTile(
                            icon: 'assets/icons/logout.svg',
                            label: 'Cerrar sesión',
                            color: const Color(0xFFF26F49),
                            onTap: () {
                              context.read<AuthBloc>().add(LogoutRequested());
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Bottom Logo/Text
                  Image.asset(
                    'assets/Logo/Imagotipo_blanco.png',
                    height: 24,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ANIMAL RECORD',
                    style: AppTypography.body3.copyWith(
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required dynamic icon,
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
            child: icon is String
                ? SvgPicture.asset(
                    icon,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.body6.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final textColor = color ?? const Color(0xFF59667A);
    return SizedBox(
      height: 56,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ListTile(
                onTap: onTap,
                leading: icon is String
                    ? SvgPicture.asset(
                        icon,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          textColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, color: textColor),
                title: Text(
                  label,
                  style: AppTypography.body3.copyWith(
                    color: color ?? const Color(0xFF2E3949),
                  ),
                ),
                trailing: SvgPicture.asset(
                  'assets/icons/arrow-right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    color ?? const Color(0xFF0072BB),
                    BlendMode.srcIn,
                  ),
                ),
                contentPadding: const EdgeInsets.only(left: 15, right: 24),
                dense: true,
                visualDensity: const VisualDensity(vertical: -4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatName(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final limitedParts = parts.take(3);

    final formattedParts = limitedParts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return formattedParts.join(' ');
  }
}
