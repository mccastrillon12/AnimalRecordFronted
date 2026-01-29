import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class AnimalsSection extends StatelessWidget {
  const AnimalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual data from BLoC/backend when implementing animal list
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis animales',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to full list
                },
                child: Text(
                  'Ver todos',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.primaryFrances.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 64),

          // Animals list or empty state
          // TODO: When implementing BLoC, replace with conditional based on actual data
          _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Empty state message
            Text(
              'No tienes ningún animal registrado todavía.',
              textAlign: TextAlign.center,
              style: AppTypography.body4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Empieza agregando uno desde',
              textAlign: TextAlign.center,
              style: AppTypography.body4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Add animal button
            SizedBox(
              width: 128,
              height: 39,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to add animal screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '+ Animal',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
