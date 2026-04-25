import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_creation_modal.dart';

class NavigationMenu extends StatefulWidget {
  final ValueChanged<String?>? onSectionChanged;
  final String? activeSection;

  const NavigationMenu({super.key, this.onSectionChanged, this.activeSection});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  bool _isExpanded = true;

  /// Maps nav index to section identifier.
  /// null = Inicio (home default).
  String? _sectionForIndex(int index) {
    switch (index) {
      case 3:
        return 'mis_animales';
      case 4:
        return null; // Inicio
      default:
        return null;
    }
  }

  int _indexForSection(String? section) {
    switch (section) {
      case 'mis_animales':
        return 3;
      default:
        return 4; // Inicio
    }
  }

  void _onItemTapped(int index) {
    // Special case: "+ Animal" opens modal, doesn't navigate
    if (index == 1) {
      showAnimalCreationModal(context);
      return;
    }

    final section = _sectionForIndex(index);
    widget.onSectionChanged?.call(section);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexForSection(widget.activeSection);

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
                color: const Color(0xFF0F1925).withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
          child: Column(
            children: [
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
                                isActive: selectedIndex == 0,
                                onTap: () => _onItemTapped(0),
                              ),
                              _NavItem(
                                svgPath: 'assets/icons/+animal.svg',
                                label: '+ Animal',
                                isActive: selectedIndex == 1,
                                onTap: () => _onItemTapped(1),
                              ),
                              _NavItem(
                                svgPath: 'assets/icons/agenda.svg',
                                label: 'Agenda',
                                isActive: selectedIndex == 2,
                                onTap: () => _onItemTapped(2),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    svgPath: 'assets/icons/animales.svg',
                    label: 'Mis animales',
                    isActive: selectedIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                  _NavItem(
                    svgPath: 'assets/icons/inicio.svg',
                    label: 'Inicio',
                    isActive: selectedIndex == 4,
                    onTap: () => _onItemTapped(4),
                  ),
                  _NavItem(
                    svgPath: 'assets/icons/vacunas.svg',
                    label: 'Carné vacunas',
                    isActive: selectedIndex == 5,
                    onTap: () => _onItemTapped(5),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.m),

        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: SvgPicture.asset(
            _isExpanded ? 'assets/icons/Up.svg' : 'assets/icons/Down.svg',
            width: AppSpacing.iconSizeSmall,
            height: AppSpacing.iconSizeSmall,
            colorFilter: const ColorFilter.mode(
              AppColors.greyBordes,
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
            SvgPicture.asset(
              svgPath,
              width: AppSpacing.iconSizeSmall,
              height: AppSpacing.iconSizeSmall,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),

            const SizedBox(height: AppSpacing.xxs),

            Text(
              label,
              style: AppTypography.body6.copyWith(
                color: textColor,

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
