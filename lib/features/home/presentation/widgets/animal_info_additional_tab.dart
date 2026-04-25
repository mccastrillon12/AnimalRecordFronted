import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_checkbox.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';

class AnimalInfoAdditionalTab extends StatelessWidget {
  final List<String> selectedTemperaments;
  final ValueChanged<List<String>> onTemperamentsChanged;
  final TextEditingController allergyController;
  final Map<String, bool> diagnoses;
  final void Function(String key, bool value) onDiagnosisChanged;
  final TextEditingController otherDiagnosisController;
  final String? housingType;
  final ValueChanged<String?> onHousingTypeChanged;
  final String? purpose;
  final ValueChanged<String?> onPurposeChanged;
  final TextEditingController feedingTypeController;
  final TextEditingController birthTypeController;
  final TextEditingController birthConditionController;

  const AnimalInfoAdditionalTab({
    super.key,
    required this.selectedTemperaments,
    required this.onTemperamentsChanged,
    required this.allergyController,
    required this.diagnoses,
    required this.onDiagnosisChanged,
    required this.otherDiagnosisController,
    required this.housingType,
    required this.onHousingTypeChanged,
    required this.purpose,
    required this.onPurposeChanged,
    required this.feedingTypeController,
    required this.birthTypeController,
    required this.birthConditionController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Info. Adicional',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Temperamento
          AppMultiSearchDropdown<String>(
            label: 'Temperamento',
            hint: 'Buscar o escribir',
            selectedItems: selectedTemperaments,
            items: const [
              'Independiente',
              'Dócil',
              'Agresivo',
              'Miedoso',
              'Juguetón',
              'Tranquilo',
              'Sociable',
            ],
            itemAsString: (item) => item,
            onChanged: onTemperamentsChanged,
          ),
          const SizedBox(height: AppSpacing.m),

          // Alergia
          CustomTextField(
            label: 'Alergia a (Opcional)',
            controller: allergyController,
          ),
          const SizedBox(height: AppSpacing.m),

          // Diagnósticos
          Text(
            'Diagnosticado con',
            style: AppTypography.body6.copyWith(color: AppColors.greyNegroV2),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...diagnoses.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomCheckbox(
                value: entry.value,
                label: entry.key,
                onChanged: (v) => onDiagnosisChanged(entry.key, v),
              ),
            ),
          ),

          if (diagnoses['Otro'] == true) ...[
            const SizedBox(height: AppSpacing.xxs),
            CustomTextField(
              label: '¿Cuál?',
              controller: otherDiagnosisController,
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          if (diagnoses['Otro'] != true) const SizedBox(height: AppSpacing.m),

          // Tipo de vivienda
          AppDropdown<String>(
            label: 'Tipo de vivienda',
            hint: 'Seleccionar',
            value: housingType,
            items: const ['Casa', 'Apartamento', 'Finca', 'Otro'],
            itemAsString: (name) => name,
            onChanged: onHousingTypeChanged,
          ),
          const SizedBox(height: AppSpacing.m),

          // Propósito del animal
          AppDropdown<String>(
            label: 'Propósito del animal',
            hint: 'Seleccionar',
            value: purpose,
            items: const [
              'Compañía',
              'Trabajo',
              'Producción de Leche',
              'Reproducción',
              'Otro',
            ],
            itemAsString: (name) => name,
            onChanged: onPurposeChanged,
          ),
          const SizedBox(height: AppSpacing.m),

          // Tipo de alimentación
          CustomTextField(
            label: 'Tipo de alimentación',
            controller: feedingTypeController,
          ),
          const SizedBox(height: AppSpacing.m),

          // Tipo de parto
          CustomTextField(
            label: 'Tipo de parto',
            controller: birthTypeController,
          ),
          const SizedBox(height: AppSpacing.m),

          // Condición al nacer
          CustomTextField(
            label: 'Condición al nacer',
            controller: birthConditionController,
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}
