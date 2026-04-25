import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';

class AnimalInfoGeneralTab extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onInactivate;

  const AnimalInfoGeneralTab({
    super.key,
    required this.animal,
    required this.onInactivate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('General', style: AppTypography.heading2)),
          const SizedBox(height: AppSpacing.xxs),
          Center(
            child: Text(
              'Creada: Enero 18, 2024. 7:10 a.m.',
              style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildInfoField('Identificación AR', animal.code),
          const SizedBox(height: AppSpacing.m),
          _buildInfoField('Creada por', 'Marc Doe'),
          const SizedBox(height: AppSpacing.m),
          _buildInfoField('Última modificación', 'Octubre 30, 2024. 9:02 p.m.'),
          const SizedBox(height: AppSpacing.m),
          _buildInfoField('Última persona en modificar', 'Marc Doe'),
          const SizedBox(height: AppSpacing.l),

          // Historial de propietarios
          Text(
            'Historial de propietarios',
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
          const SizedBox(height: AppSpacing.xxs),
          _buildHistoryItem('1. John Doe', 'Enero 18, 2024'),
          _buildHistoryItem('2. Bárbara James', 'Octubre 30, 2024'),
          const SizedBox(height: AppSpacing.l),

          // Historial de nombres
          Text(
            'Historial de nombres',
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
          const SizedBox(height: AppSpacing.xxs),
          _buildHistoryItem('1. ${animal.name}', 'Enero 18, 2024'),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title - ',
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
            TextSpan(
              text: date,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
          ],
        ),
      ),
    );
  }
}
