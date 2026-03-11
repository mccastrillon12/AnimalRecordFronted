import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';

class BiometricEnableDialog extends StatelessWidget {
  final VoidCallback onEnable;

  const BiometricEnableDialog({super.key, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: 'La biometría no está activa',
      description:
          'Actualmente no tienes habilitado el ingreso con huella digital o reconocimiento facial en este dispositivo. Si decides activarlo, tu sesión se cerrará y deberás iniciar sesión nuevamente para completar la configuración.',
      confirmLabel: 'Activar biometría',
      confirmColor: const Color(0xFFFA2844),
      onConfirm: onEnable,
    );
  }
}
