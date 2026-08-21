import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<MedicalDocumentCategory?> showMedicalDocumentClassificationDialog({
  required BuildContext context,
  required MedicalDocumentEntity document,
  required MedicalDocumentCategory initialCategory,
}) async {
  final detectedCategories = _detectedCategories(document, initialCategory);
  final detectedCategoriesLabel = _categoryListLabel(detectedCategories);
  final isUnidentified =
      detectedCategories.length == 1 &&
      detectedCategories.single == MedicalDocumentCategory.other;
  MedicalDocumentCategory? selectedCategory =
      isUnidentified || initialCategory == MedicalDocumentCategory.other
      ? null
      : initialCategory;
  MedicalDocumentCategory? confirmedCategory;

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
                  'La IA ha detectado que el archivo que intenta cargar corresponde a: ',
            ),
            TextSpan(
              text: '$detectedCategoriesLabel.',
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
            AppDropdown<MedicalDocumentCategory>(
              label: 'Tipo de contenido',
              hint: 'Tipo de contenido',
              value: selectedCategory,
              items: _selectableCategories,
              itemAsString: _categoryLabel,
              preserveOrder: true,
              showClearOption: false,
              isInline: true,
              pushContent: true,
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => selectedCategory = value);
              },
            ),
          ],
        ),
        confirmLabel: 'Continuar',
        confirmColor: AppColors.aiViolet,
        isConfirmEnabled: selectedCategory != null,
        onConfirm: () => confirmedCategory = selectedCategory,
      ),
    ),
  );
  return confirmedCategory;
}

List<MedicalDocumentCategory> _detectedCategories(
  MedicalDocumentEntity document,
  MedicalDocumentCategory fallback,
) {
  final categories = <MedicalDocumentCategory>[];
  void add(MedicalDocumentCategory? category) {
    if (category != null && !categories.contains(category)) {
      categories.add(category);
    }
  }

  add(document.primaryDetectedCategory);
  for (final detected in document.detectedCategories) {
    add(detected.category);
  }
  if (categories.isEmpty) add(fallback);
  return List.unmodifiable(categories);
}

String _categoryListLabel(List<MedicalDocumentCategory> categories) {
  final labels = categories.map(_categoryLabel).toList();
  if (labels.length < 2) return labels.single;
  if (labels.length == 2) return '${labels.first} y ${labels.last}';
  return '${labels.take(labels.length - 1).join(', ')} y ${labels.last}';
}

String _categoryLabel(MedicalDocumentCategory category) =>
    category == MedicalDocumentCategory.other
    ? 'Archivo no identificado'
    : category.label;

const _selectableCategories = [
  MedicalDocumentCategory.prescription,
  MedicalDocumentCategory.medicalOrder,
  MedicalDocumentCategory.referral,
  MedicalDocumentCategory.vaccinationCard,
  MedicalDocumentCategory.clinicalHistory,
];

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
