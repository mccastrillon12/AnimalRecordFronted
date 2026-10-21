import 'dart:async';

import 'package:animal_record/core/widgets/menus/app_popup_action_menu.dart';
import 'package:flutter/material.dart';

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
    return AppPopupActionMenu<String>(
      menuKey: menuKey,
      actions: [
        AppPopupMenuAction(
          key: itemKey,
          value: value,
          label: label,
          iconAsset: iconAsset,
          iconColor: iconColor,
        ),
      ],
      offset: offset,
      position: position,
      menuPadding: menuPadding,
      menuWidth: menuWidth,
      trigger: trigger,
      onSelected: onSelected,
    );
  }
}
