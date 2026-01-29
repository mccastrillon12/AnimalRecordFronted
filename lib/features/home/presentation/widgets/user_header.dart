import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryIndigo,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Logo section
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.l,
              bottom: AppSpacing.m,
            ),
            child: Image.asset(
              'assets/Logo/Imagotipo_blanco.png',
              width: 40,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),

          // User info section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: Row(
              children: [
                // Profile image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryIndigo,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.m),

                // User info
                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (previous, current) {
                      // Only rebuild if it's a success state or if transitioning out of success
                      if (current is AuthSuccess || previous is AuthSuccess) {
                        return true;
                      }
                      return false;
                    },
                    builder: (context, state) {
                      String name = 'Usuario';
                      String role = 'Propietario';

                      if (state is AuthSuccess) {
                        name = state.user.name;
                        if (state.user.roles.isNotEmpty) {
                          role = state.user.roles.first == 'PROPIETARIO_MASCOTA'
                              ? 'Propietario'
                              : state.user.roles.first;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Greeting
                          Text(
                            'Hola, $name',
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // User role
                          Text(
                            role,
                            style: AppTypography.body3.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Notification bell
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s),
        ],
      ),
    );
  }
}
