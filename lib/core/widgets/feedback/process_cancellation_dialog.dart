import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showProcessCancellationDialog(BuildContext context) async {
  var confirmed = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ConfirmDialog(
      title: '¿Desea cancelar el proceso?',
      description: 'Perderá los datos diligenciados al momento.',
      confirmLabel: 'Si',
      cancelLabel: 'No',
      width: 325,
      confirmColor: const Color(0xFFFA2844),
      onConfirm: () => confirmed = true,
      onCancel: () => confirmed = false,
    ),
  );
  return confirmed;
}
