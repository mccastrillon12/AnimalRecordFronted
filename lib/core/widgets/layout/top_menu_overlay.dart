import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

/// A single item in the [TopMenuOverlay].
class TopMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TopMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Reusable overlay menu that slides down from the top of the screen.
///
/// Usage:
/// ```dart
/// TopMenuOverlay(
///   isOpen: _menuOpen,
///   onClose: () => setState(() => _menuOpen = false),
///   items: [...],
/// )
/// ```
///
/// Must be placed inside a [Stack] so it can overlay content.
class TopMenuOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<TopMenuItem> items;

  final VoidCallback onToggle;

  const TopMenuOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onToggle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop (only present/blocking when menu is open)
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: AnimatedOpacity(
                opacity: isOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
          ),

        // Menu Panel & Trigger Assembly (always present at top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The expanding white menu component
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgBlancoAntiFlash,
                    borderRadius: AppBorders.onlyBottom(
                      AppBorders.radiusXLarge,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 450),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeOutCubic,
                    sizeCurve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    crossFadeState: isOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(
                      width: double.infinity,
                      height: 32, // The persistent white peek area when closed
                    ),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        top: AppSpacing.s,
                        bottom: AppSpacing.l,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close button row
                          _buildGrid(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Trigger chevron (always immediately below the white component)
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      isOpen ? 'assets/icons/Up.svg' : 'assets/icons/Down.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isOpen
                            ? AppColors.white.withValues(alpha: 0.5)
                            : AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    // Split items into rows of 3
    final List<List<TopMenuItem>> rows = [];
    for (int i = 0; i < items.length; i += 3) {
      final end = (i + 3 > items.length) ? items.length : i + 3;
      rows.add(items.sublist(i, end));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final row = entry.value;

        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex < rows.length - 1 ? AppSpacing.l : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((item) => _buildMenuItem(item)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(TopMenuItem item) {
    return GestureDetector(
      onTap: () {
        onClose();
        item.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 46,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: AppColors.greyTextos),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTypography.body6.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w500,
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
