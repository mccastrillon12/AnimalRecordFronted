import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/custom_date_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/edit_name_dialog.dart';
import 'package:animal_record/features/catalogs/domain/entities/catalog_item_entity.dart';
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
  final String? selectedIdentificationType;
  final ValueChanged<String?> onIdentificationTypeChanged;
  final TextEditingController identificationNumberController;
  final String? belongsToAssociation;
  final ValueChanged<String?> onBelongsToAssociationChanged;
  final String? selectedAssociation;
  final ValueChanged<String?> onAssociationChanged;
  final VoidCallback? onEditPhoto;
  final bool isUploadingPicture;
  final String? localPhotoPath;
  final bool photoDeleted;
  final ValueChanged<String>? onNameSaved;

  // Dynamic catalog data from API
  final List<CatalogItemEntity> identificationTypeOptions;
  final List<CatalogItemEntity> associationOptions;

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
    this.selectedIdentificationType,
    required this.onIdentificationTypeChanged,
    required this.identificationNumberController,
    required this.belongsToAssociation,
    required this.onBelongsToAssociationChanged,
    required this.selectedAssociation,
    required this.onAssociationChanged,
    this.onEditPhoto,
    this.isUploadingPicture = false,
    this.localPhotoPath,
    this.photoDeleted = false,
    this.onNameSaved,
    this.identificationTypeOptions = const [],
    this.associationOptions = const [],
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

  /// Builds the photo content with priority:
  /// 1. Local file (just picked, not yet uploaded)
  /// 2. Deleted state (show placeholder)
  /// 3. Network image (from backend)
  /// 4. Fallback placeholder
  Widget _buildPhotoContent() {
    // Priority 1: Local file selected (instant preview)
    if (localPhotoPath != null) {
      return Image.file(
        File(localPhotoPath!),
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      );
    }

    // Priority 2: Photo was deleted (show placeholder immediately)
    if (photoDeleted) {
      return Center(
        child: SvgPicture.asset(
          _iconForFamily(animal.family),
          width: AppSpacing.iconSizeMedium,
          height: 35,
        ),
      );
    }

    // Priority 3: Network image from backend
    if (animal.imageUrl != null) {
      return Image.network(
        animal.imageUrl!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: SvgPicture.asset(
            _iconForFamily(animal.family),
            width: AppSpacing.iconSizeMedium,
            height: 35,
          ),
        ),
      );
    }

    // Priority 4: Fallback placeholder
    return Center(
      child: SvgPicture.asset(
        _iconForFamily(animal.family),
        width: AppSpacing.iconSizeMedium,
        height: 35,
      ),
    );
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
                      clipBehavior: Clip.antiAlias,
                      child: _buildPhotoContent(),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: GestureDetector(
                        onTap: onEditPhoto,
                        child: Container(
                          width: AppSpacing.xl,
                          height: AppSpacing.xl,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: AppBorders.small(),
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
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nameController,
                      builder: (context, value, child) {
                        return Text(
                          value.text.isNotEmpty ? value.text : animal.name,
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditNameDialog(
                            currentName: nameController.text.isNotEmpty
                                ? nameController.text
                                : animal.name,
                            onSave: (newName) {
                              nameController.text = newName;
                              // Trigger the API update for the name change
                              onNameSaved?.call(newName);
                            },
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.edit,
                        size: AppSpacing.m,
                        color: AppColors.greyBordes,
                      ),
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
            AppDropdown<String>(
              label: 'Tipo de identificación',
              hint: 'Seleccionar',
              value: selectedIdentificationType,
              isInline: true,
              items: identificationTypeOptions.map((t) => t.name).toList(),
              itemAsString: (name) => name,
              onChanged: onIdentificationTypeChanged,
            ),
            const SizedBox(height: AppSpacing.m),
            CustomTextField(
              label: 'Número de identificación',
              controller: identificationNumberController,
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
            AppDropdown<String>(
              label: 'Asociaciones',
              hint: 'Seleccionar asociación',
              value: selectedAssociation,
              isInline: true,
              items: associationOptions.map((a) => a.name).toList(),
              itemAsString: (name) => name,
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
        const SizedBox(height: AppSpacing.xxs),
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
