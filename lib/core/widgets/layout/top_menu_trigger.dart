import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';

/// A trigger button for the [TopMenuOverlay].
///
/// Displays a chevron icon that toggles between up/down based on [isMenuOpen].
/// Decoupled from the menu overlay itself — only emits toggle events.
class TopMenuTrigger extends StatelessWidget {
  final bool isMenuOpen;
  final VoidCallback onToggle;

  const TopMenuTrigger({
    super.key,
    required this.isMenuOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SvgPicture.asset(
          isMenuOpen ? 'assets/icons/Up.svg' : 'assets/icons/Down.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isMenuOpen ? AppColors.white.withValues(alpha: 0.5) : AppColors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
