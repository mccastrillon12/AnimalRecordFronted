import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'animal_card.dart';

class AnimalsSection extends StatelessWidget {
  const AnimalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual data from BLoC/backend
    final bool hasAnimals = false;

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

              if (hasAnimals)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all animals list
                  },
                  child: Text(
                    'Ver todos',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.primaryFrances,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.l),

          // Animals list or empty state
          if (hasAnimals)
            // TODO: Replace with actual list from backend
            _buildAnimalsList()
          else
            _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildAnimalsList() {
    // TODO: Replace with BlocBuilder to get actual animals
    return const Column(
      children: [
        AnimalCard(name: 'Max', species: 'Perro', imageUrl: null),
        SizedBox(height: AppSpacing.m),
        AnimalCard(name: 'Luna', species: 'Gato', imageUrl: null),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
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

            const SizedBox(height: AppSpacing.xl),

            // Add animal button
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to add animal screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.m,
                ),
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
          ],
        ),
      ),
    );
  }
}
