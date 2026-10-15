import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppPopupMenuAction<T> {
  final T value;
  final String label;
  final String iconAsset;
  final Key? key;
  final Color? iconColor;
  final Color? textColor;

  const AppPopupMenuAction({
    required this.value,
    required this.label,
    required this.iconAsset,
    this.key,
    this.iconColor,
    this.textColor,
  });
}

class AppPopupActionMenu<T> extends StatelessWidget {
  final Key? menuKey;
  final List<AppPopupMenuAction<T>> actions;
  final Offset offset;
  final PopupMenuPosition position;
  final EdgeInsetsGeometry? menuPadding;
  final double menuWidth;
  final double itemHeight;
  final bool enabled;
  final ShapeBorder shape;
  final Widget? trigger;
  final Widget? icon;
  final FutureOr<void> Function(T value) onSelected;

  const AppPopupActionMenu({
    super.key,
    this.menuKey,
    required this.actions,
    required this.offset,
    this.position = PopupMenuPosition.over,
    this.menuPadding,
    this.menuWidth = 203,
    this.itemHeight = 47,
    this.enabled = true,
    this.shape = const RoundedRectangleBorder(),
    this.trigger,
    this.icon,
    required this.onSelected,
  }) : assert(
         (trigger == null) != (icon == null),
         'Provide either trigger or icon, but not both.',
       );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        key: menuKey,
        enabled: enabled,
        padding: EdgeInsets.zero,
        position: position,
        offset: offset,
        menuPadding: menuPadding,
        shape: shape,
        constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
        color: AppColors.white,
        elevation: 4,
        onSelected: onSelected,
        itemBuilder: (_) => actions
            .map(
              (action) => PopupMenuItem<T>(
                key: action.key,
                value: action.value,
                height: itemHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      action.iconAsset,
                      width: AppSpacing.iconSizeSmall,
                      height: AppSpacing.iconSizeSmall,
                      colorFilter: action.iconColor == null
                          ? null
                          : ColorFilter.mode(
                              action.iconColor!,
                              BlendMode.srcIn,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body4.copyWith(
                          color: action.textColor ?? AppColors.greyTextos,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
        icon: icon,
        child: icon == null ? trigger : null,
      ),
    );
  }
}
