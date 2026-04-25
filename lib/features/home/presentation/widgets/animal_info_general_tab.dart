import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';

class AnimalInfoGeneralTab extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onInactivate;

  const AnimalInfoGeneralTab({
    super.key,
    required this.animal,
    required this.onInactivate,
  });

  /// Formats an ISO 8601 date string into a human-readable Spanish format.
  /// Example: '2026-04-25T15:00:00.000Z' → 'Abril 25, 2026. 10:00 a.m.'
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No disponible';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      final month = months[date.month];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour >= 12 ? 'p.m.' : 'a.m.';
      return '$month ${date.day}, ${date.year}. $hour:$minute $amPm';
    } catch (_) {
      return 'No disponible';
    }
  }

  /// Formats a short date (without time) for history items.
  /// Example: '2026-04-25T15:00:00.000Z' → 'Abril 25, 2026'
  String _formatShortDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No disponible';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      final month = months[date.month];
      return '$month ${date.day}, ${date.year}';
    } catch (_) {
      return 'No disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Get the owner name from the animal data or fall back to the auth user
        String ownerName = animal.ownerName ?? '';
        if (ownerName.isEmpty && authState is AuthSuccess) {
          ownerName = authState.user.name;
        }
        if (ownerName.isEmpty) {
          ownerName = 'No disponible';
        }

        // Format the owner name (capitalize each word, max 3 words)
        final formattedOwnerName = _formatOwnerName(ownerName);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('General', style: AppTypography.heading2)),
              const SizedBox(height: AppSpacing.xxs),
              Center(
                child: Text(
                  'Creada: ${_formatDate(animal.createdAt)}',
                  style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildInfoField('Identificación AR', animal.code),
              const SizedBox(height: AppSpacing.m),
              _buildInfoField('Creada por', formattedOwnerName),
              const SizedBox(height: AppSpacing.m),
              _buildInfoField(
                'Última modificación',
                _formatDate(animal.updatedAt ?? animal.createdAt),
              ),
              const SizedBox(height: AppSpacing.m),
              _buildInfoField('Última persona en modificar', formattedOwnerName),
              const SizedBox(height: AppSpacing.l),

              // Historial de propietarios
              Text(
                'Historial de propietarios',
                style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _buildHistoryItem(
                '1. $formattedOwnerName',
                _formatShortDate(animal.createdAt),
              ),
              const SizedBox(height: AppSpacing.l),

              // Historial de nombres
              Text(
                'Historial de nombres',
                style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _buildHistoryItem(
                '1. ${animal.name}',
                _formatShortDate(animal.updatedAt),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Formats a full name: capitalize each word, limit to 3 words.
  String _formatOwnerName(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final limitedParts = parts.take(3);
    return limitedParts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join(' ');
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
