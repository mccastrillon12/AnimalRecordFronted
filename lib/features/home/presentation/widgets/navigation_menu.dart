import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      child: Column(
        children: [
          // First row: Mapa, +Animal, Agenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                label: 'Mapa',
                onTap: () {
                  // TODO: Navigate to map
                },
              ),
              _NavItem(
                icon: Icons.add_circle,
                label: '+ Animal',
                isPrimary: true,
                onTap: () {
                  // TODO: Navigate to add animal
                },
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Agenda',
                onTap: () {
                  // TODO: Navigate to agenda
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.l),

          // Second row: Mis animales, Inicio, Carné vacunas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.pets_outlined,
                label: 'Mis animales',
                onTap: () {
                  // Already on home, maybe scroll to animals section
                },
              ),
              _NavItem(
                icon: Icons.home,
                label: 'Inicio',
                isActive: true,
                onTap: () {
                  // Already on home
                },
              ),
              _NavItem(
                icon: Icons.badge_outlined,
                label: 'Carné vacunas',
                onTap: () {
                  // TODO: Navigate to vaccination card
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isPrimary;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.primaryFrances
        : isPrimary
        ? AppColors.primaryFrances
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.white
                  : AppColors.greyClaro.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: isPrimary
                  ? Border.all(color: AppColors.greyMedio, width: 1)
                  : null,
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: AppTypography.body6.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
