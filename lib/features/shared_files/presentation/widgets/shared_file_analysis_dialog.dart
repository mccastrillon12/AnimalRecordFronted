import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SharedFileContentType { medicalFormula, medicalOrder, medicalReferral }

extension SharedFileContentTypeLabel on SharedFileContentType {
  String get label => switch (this) {
    SharedFileContentType.medicalFormula => 'Fórmula médica',
    SharedFileContentType.medicalOrder => 'Orden médica',
    SharedFileContentType.medicalReferral => 'Remisión médica',
  };
}

Future<SharedFileContentType?> showSharedFileAnalysisDialog({
  required BuildContext context,
  SharedFileContentType detectedType = SharedFileContentType.medicalFormula,
}) async {
  var selectedType = detectedType;
  SharedFileContentType? confirmedType;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => ConfirmDialog(
        title: 'Análisis de archivo adjunto',
        titleColor: AppColors.aiViolet,
        headerLeading: const _AiIndicator(),
        richDescription: TextSpan(
          children: [
            const TextSpan(
              text:
                  'Hemos detectado que el archivo que intenta cargar corresponde a: ',
            ),
            TextSpan(
              text: '${detectedType.label}.',
              style: AppTypography.body6.copyWith(
                color: AppColors.greyTextos,
                height: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Si no es correcto por favor cambie el tipo de contenido para '
              'continuar con la carga del archivo.',
              style: AppTypography.body6.copyWith(
                color: AppColors.greyTextos,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            AppDropdown<SharedFileContentType>(
              label: 'Tipo de contenido',
              hint: 'Seleccione el tipo de contenido',
              value: selectedType,
              items: SharedFileContentType.values,
              itemAsString: (type) => type.label,
              preserveOrder: true,
              showClearOption: false,
              isInline: true,
              pushContent: true,
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => selectedType = value);
              },
            ),
          ],
        ),
        confirmLabel: 'Continuar',
        confirmColor: AppColors.aiViolet,
        onConfirm: () => confirmedType = selectedType,
      ),
    ),
  );

  return confirmedType;
}

class _AiIndicator extends StatelessWidget {
  const _AiIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppIcons.magicStar, width: 18, height: 18),
        const SizedBox(width: 4),
        Text(
          'IA',
          style: AppTypography.body6.copyWith(color: AppColors.aiViolet),
        ),
      ],
    );
  }
}
