import 'dart:async';

import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/menus/app_single_action_popup_menu.dart';
import 'package:flutter/material.dart';

class VaccinationSendMenu extends StatelessWidget {
  static const _menuCloseDuration = Duration(milliseconds: 320);

  final VoidCallback onSend;
  final Key? menuKey;

  const VaccinationSendMenu({super.key, required this.onSend, this.menuKey});

  @override
  Widget build(BuildContext context) {
    return AppSingleActionPopupMenu(
      menuKey: menuKey,
      itemKey: const Key('send-vaccination-document-menu-item'),
      value: 'send',
      label: 'Enviar',
      iconAsset: AppIcons.export,
      iconColor: AppColors.greyMedio,
      position: PopupMenuPosition.under,
      offset: const Offset(-24, 0),
      menuPadding: EdgeInsets.zero,
      menuWidth: 128,
      onSelected: (_) async {
        await Future<void>.delayed(_menuCloseDuration);
        onSend();
      },
      trigger: const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            Icons.more_vert,
            color: AppColors.white,
            size: AppSpacing.iconSizeSmall,
          ),
        ),
      ),
    );
  }
}
