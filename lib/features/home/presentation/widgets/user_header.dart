import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

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
            child: Text(
              '.AR',
              style: AppTypography.heading1.copyWith(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Greeting
                      Text(
                        'Hola, John Doe', // TODO: Replace with actual user name
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // User role
                      Text(
                        'Propietario', // TODO: Replace with actual user role
                        style: AppTypography.body5.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
