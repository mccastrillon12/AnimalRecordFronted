import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/custom_date_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import 'package:animal_record/core/widgets/dropdowns/custom_dropdown_field.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalInfoBasicTab extends StatelessWidget {
  final AnimalModel animal;
  final TextEditingController nameController;
  final String? reproductiveState;
  final ValueChanged<String?> onReproductiveStateChanged;
  final DateTime? birthDate;
  final ValueChanged<DateTime> onBirthDateChanged;
  final bool unknownExactDate;
  final ValueChanged<bool> onUnknownExactDateChanged;
  final TextEditingController weightKgController;
  final TextEditingController colorDescController;
  final String? hasIdentification;
  final ValueChanged<String?> onHasIdentificationChanged;
  final String? belongsToAssociation;
  final ValueChanged<String?> onBelongsToAssociationChanged;
  final String? selectedAssociation;
  final ValueChanged<String?> onAssociationChanged;

  const AnimalInfoBasicTab({
    super.key,
    required this.animal,
    required this.nameController,
    required this.reproductiveState,
    required this.onReproductiveStateChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.unknownExactDate,
    required this.onUnknownExactDateChanged,
    required this.weightKgController,
    required this.colorDescController,
    required this.hasIdentification,
    required this.onHasIdentificationChanged,
    required this.belongsToAssociation,
    required this.onBelongsToAssociationChanged,
    required this.selectedAssociation,
    required this.onAssociationChanged,
  });

  String _iconForFamily(String family) {
    switch (family.toLowerCase()) {
      case 'felino':
        return 'assets/illustrations/cat_icon.svg';
      case 'canino':
        return 'assets/illustrations/dog_icon.svg';
      case 'bovino':
        return 'assets/illustrations/bovino_icon.svg';
      case 'equino':
        return 'assets/illustrations/equino_icon.svg';
      default:
        return 'assets/illustrations/bovino_icon.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + Name header
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.bgHielo,
                        borderRadius: AppBorders.medium(),
                      ),
                      child: Center(
                        child: animal.imageUrl != null
                            ? ClipRRect(
                                borderRadius: AppBorders.medium(),
                                child: Image.network(
                                  animal.imageUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      SvgPicture.asset(
                                        _iconForFamily(animal.family),
                                        width: AppSpacing.iconSizeMedium,
                                        height: 35,
                                      ),
                                ),
                              )
                            : SvgPicture.asset(
                                _iconForFamily(animal.family),
                                width: AppSpacing.iconSizeMedium,
                                height: 35,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: -4,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryIndigo,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: AppSpacing.m,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animal.name,
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: AppSpacing.m,
                      color: AppColors.greyBordes,
                    ),
                  ],
                ),
                Text(
                  '${animal.breed ?? animal.family}, ${animal.sexDisplay}.',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyMedio,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Estado reproductivo
          Text('Estado reproductivo', style: AppTypography.body6),
          const SizedBox(height: AppSpacing.xs),
          CustomRadioButton<String>(
            value: 'esterilizado',
            groupValue: reproductiveState,
            label: 'Esterilizado',
            onChanged: onReproductiveStateChanged,
          ),
          const SizedBox(height: AppSpacing.m),
          CustomRadioButton<String>(
            value: 'no_esterilizado',
            groupValue: reproductiveState,
            label: 'No esterilizado',
            onChanged: onReproductiveStateChanged,
          ),
          const SizedBox(height: AppSpacing.m),
          CustomRadioButton<String>(
            value: 'desconocido',
            groupValue: reproductiveState,
            label: 'Desconocido',
            onChanged: onReproductiveStateChanged,
          ),
          const SizedBox(height: AppSpacing.m),

          // Fecha de nacimiento
          CustomDateField(
            label: 'Fecha de nacimiento',
            value: birthDate,
            onChanged: onBirthDateChanged,
            enabled: !unknownExactDate,
            showAge: true,
          ),
          const SizedBox(height: AppSpacing.m),

          // Toggle fecha exacta
          GestureDetector(
            onTap: () => onUnknownExactDateChanged(!unknownExactDate),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: AppSpacing.iconSizeSmall,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: unknownExactDate
                        ? AppColors.primaryFrances
                        : AppColors.greyDelineante,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: unknownExactDate
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'No sé la fecha exacta',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyTextos,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Color y marcas
          _buildTextArea(
            label: 'Color y marcas distintivas (Opcional)',
            hint: 'Haz una breve descripción',
            controller: colorDescController,
          ),
          const SizedBox(height: AppSpacing.m),

          // Identificación
          Text(
            '¿Tiene identificación? (Chip, arete, otros)',
            style: AppTypography.body6,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              CustomRadioButton<String>(
                value: 'si',
                groupValue: hasIdentification,
                label: 'Si',
                onChanged: onHasIdentificationChanged,
              ),
              const SizedBox(width: AppSpacing.xxxl),
              CustomRadioButton<String>(
                value: 'no',
                groupValue: hasIdentification,
                label: 'No',
                onChanged: onHasIdentificationChanged,
              ),
            ],
          ),

          if (hasIdentification == 'si') ...[
            const SizedBox(height: AppSpacing.m),
            CustomDropdownField<String>(
              label: 'Tipo de identificación',
              hint: 'Seleccionar',
              value: null,
              items: const [
                DropdownMenuItem(value: 'Microchip', child: Text('Microchip')),
                DropdownMenuItem(value: 'Arete', child: Text('Arete')),
                DropdownMenuItem(value: 'Tatuaje', child: Text('Tatuaje')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.m),
            CustomTextField(
              label: 'Número de identificación',
              controller: TextEditingController(),
            ),
          ],
          const SizedBox(height: AppSpacing.m),

          // Asociación
          Text('¿Pertenece a alguna asociación?', style: AppTypography.body6),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              CustomRadioButton<String>(
                value: 'si',
                groupValue: belongsToAssociation,
                label: 'Si',
                onChanged: onBelongsToAssociationChanged,
              ),
              const SizedBox(width: AppSpacing.xxxl),
              CustomRadioButton<String>(
                value: 'no',
                groupValue: belongsToAssociation,
                label: 'No',
                onChanged: onBelongsToAssociationChanged,
              ),
            ],
          ),
          if (belongsToAssociation == 'si') ...[
            const SizedBox(height: AppSpacing.m),
            CustomDropdownField<String>(
              label: 'Asociaciones',
              hint: 'Seleccionar asociación',
              value: selectedAssociation,
              isInline: true,
              items: const [
                DropdownMenuItem(
                  value: 'Asociación 1',
                  child: Text('Asociación 1'),
                ),
                DropdownMenuItem(
                  value: 'Asociación 2',
                  child: Text('Asociación 2'),
                ),
                DropdownMenuItem(
                  value: 'Asociación 3',
                  child: Text('Asociación 3'),
                ),
              ],
              onChanged: onAssociationChanged,
            ),
          ],
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label
                        .replaceAll(' (Opcional)', '')
                        .replaceAll('(Opcional)', '')
                        .trim(),
                    style: AppTypography.body6,
                  ),
                  if (label.contains('(Opcional)'))
                    TextSpan(
                      text: ' (Opcional)',
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyBordes,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 50,
          style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            hintText: hint,
            hintStyle: AppTypography.body4.copyWith(
              color: AppColors.greyBordes,
            ),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            counterStyle: AppTypography.body6.copyWith(
              color: AppColors.greyBordes,
            ),
          ),
        ),
      ],
    );
  }
}
