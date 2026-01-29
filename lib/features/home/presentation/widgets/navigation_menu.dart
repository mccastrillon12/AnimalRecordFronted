import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  bool _isExpanded = true;
  int _selectedIndex = 4; // Default to 'Inicio' (index 4)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F1925).withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
          child: Column(
            children: [
              // First row: Mapa, +Animal, Agenda (Collapsible)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          const SizedBox(height: 24),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // Second row: Mis animales, Inicio, Carné vacunas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        ),

        const SizedBox(height: 8),

        // Toggle Expand/Collapse Arrow
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: SvgPicture.asset(
            _isExpanded ? 'assets/icons/Up.svg' : 'assets/icons/Down.svg',
            width: 24,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.greyMedio,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
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
    final iconColor = isActive
        ? const Color(0xFF0072BB)
        : const Color(0xFF59667A);
    final textColor = isActive
        ? const Color(0xFF2E3949)
        : const Color(0xFF59667A);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            SvgPicture.asset(
              svgPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),

            const SizedBox(height: 2),

            // Label
            Text(
              label,
              style: AppTypography.body6.copyWith(
                color: textColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
