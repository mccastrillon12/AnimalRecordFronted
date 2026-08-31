import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSingleActionPopupMenu extends StatelessWidget {
  final Key? menuKey;
  final Key? itemKey;
  final String value;
  final String label;
  final String iconAsset;
  final Color? iconColor;
  final Offset offset;
  final PopupMenuPosition position;
  final EdgeInsetsGeometry? menuPadding;
  final double menuWidth;
  final Widget trigger;
  final FutureOr<void> Function(String value) onSelected;

  const AppSingleActionPopupMenu({
    super.key,
    this.menuKey,
    this.itemKey,
    required this.value,
    required this.label,
    required this.iconAsset,
    this.iconColor,
    required this.offset,
    this.position = PopupMenuPosition.over,
    this.menuPadding,
    this.menuWidth = 203,
    required this.trigger,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        key: menuKey,
        padding: EdgeInsets.zero,
        position: position,
        offset: offset,
        menuPadding: menuPadding,
        shape: const RoundedRectangleBorder(),
        constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
        color: AppColors.white,
        elevation: 4,
        onSelected: onSelected,
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            key: itemKey,
            value: value,
            height: 47,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: AppSpacing.iconSizeSmall,
                  height: AppSpacing.iconSizeSmall,
                  colorFilter: iconColor == null
                      ? null
                      : ColorFilter.mode(iconColor!, BlendMode.srcIn),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyTextos,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: trigger,
      ),
    );
  }
}
