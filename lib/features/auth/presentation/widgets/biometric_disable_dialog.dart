import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';

class BiometricDisableDialog extends StatelessWidget {
  final VoidCallback onDisable;

  const BiometricDisableDialog({super.key, required this.onDisable});

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: '¿Desea desactivar la biometría?',
      description:
          'Actualmente tienes activado el ingreso con huella o Face ID. Si lo desactivas, podrás volver a activarlo más adelante.',
      confirmLabel: 'Desactivar',
      confirmColor: const Color(0xFFFF3B30),
      onConfirm: onDisable,
    );
  }
}
