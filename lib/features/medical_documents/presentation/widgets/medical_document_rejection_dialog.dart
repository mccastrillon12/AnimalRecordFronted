import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MedicalDocumentRejectionReason { incorrectInformation, wrongAnimal, other }

extension MedicalDocumentRejectionReasonLabel
    on MedicalDocumentRejectionReason {
  String get label => switch (this) {
    MedicalDocumentRejectionReason.incorrectInformation =>
      'Información incorrecta',
    MedicalDocumentRejectionReason.wrongAnimal =>
      'El archivo no es el correspondiente al animal',
    MedicalDocumentRejectionReason.other => 'Otros',
  };
}

Future<MedicalDocumentRejectionReason?> showMedicalDocumentRejectionDialog({
  required BuildContext context,
  Future<void> Function()? onCancel,
}) async {
  MedicalDocumentRejectionReason? selectedReason;
  MedicalDocumentRejectionReason? confirmedReason;
  Future<void>? cancellation;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => ConfirmDialog(
        title: '¿Qué estuvo mal?',
        titleColor: AppColors.aiViolet,
        headerLeading: const _AiIndicator(),
        description:
            'Selecciona el motivo por el cual no desea subir el archivo. '
            'Si fue error de lectura podrá reintentarlo.',
        content: AppDropdown<MedicalDocumentRejectionReason>(
          label: 'Seleccionar el motivo:',
          hint: 'Motivo',
          value: selectedReason,
          items: MedicalDocumentRejectionReason.values,
          itemAsString: (reason) => reason.label,
          preserveOrder: true,
          showClearOption: false,
          isInline: true,
          pushContent: true,
          onChanged: (value) {
            setDialogState(() => selectedReason = value);
          },
        ),
        confirmLabel: 'Reintentar',
        confirmColor: AppColors.aiViolet,
        isConfirmEnabled: selectedReason != null,
        onConfirm: () => confirmedReason = selectedReason,
        onCancel: () => cancellation = onCancel?.call(),
      ),
    ),
  );

  await cancellation;
  return confirmedReason;
}

class _AiIndicator extends StatelessWidget {
  const _AiIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppIcons.magicStar, width: 18, height: 18),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          'IA',
          style: AppTypography.body6.copyWith(color: AppColors.aiViolet),
        ),
      ],
    );
  }
}
