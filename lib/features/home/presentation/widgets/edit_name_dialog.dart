import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';

class EditNameDialog extends StatefulWidget {
  final String currentName;
  final ValueChanged<String> onSave;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onSave,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _nameController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _nameController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final newText = _nameController.text.trim();
    final isModified = newText.isNotEmpty && newText != widget.currentName;
    if (isModified != _isModified) {
      setState(() {
        _isModified = isModified;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: 'Cambiar nombre',
      richDescription: TextSpan(
        children: [
          const TextSpan(
            text:
                'Todos los elementos en AR que incluyan el nombre actual del animal se actualizarán automáticamente. Después de este cambio, ',
          ),
          TextSpan(
            text:
                'no podrás modificar el nombre nuevamente hasta pasados 30 días.',
            style: AppTypography.body6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: CustomTextField(
        label: 'Nombre',
        controller: _nameController,
        hint: 'Ingresa el nombre',
      ),
      confirmLabel: 'Guardar',
      confirmColor: AppColors.secondaryCoral,
      isConfirmEnabled: _isModified,
      onConfirm: () => widget.onSave(_nameController.text.trim()),
    );
  }
}
