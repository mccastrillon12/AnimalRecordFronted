import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 4; // Default to 'Inicio' (index 4)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                svgPath: 'assets/icons/mapa.svg',
                label: 'Mapa',
                isActive: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _NavItem(
                svgPath: 'assets/icons/+animal.svg',
                label: '+ Animal',
                isActive: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _NavItem(
                svgPath: 'assets/icons/agenda.svg',
                label: 'Agenda',
                isActive: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.l),

          // Second row: Mis animales, Inicio, Carné vacunas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                svgPath: 'assets/icons/animales.svg',
                label: 'Mis animales',
                isActive: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
              _NavItem(
                svgPath: 'assets/icons/inicio.svg',
                label: 'Inicio',
                isActive: _selectedIndex == 4,
                onTap: () => _onItemTapped(4),
              ),
              _NavItem(
                svgPath: 'assets/icons/vacunas.svg',
                label: 'Carné vacunas',
                isActive: _selectedIndex == 5,
                onTap: () => _onItemTapped(5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String svgPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.svgPath,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF0072BB) : const Color(0xFF59667A);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.greyClaro.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
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
