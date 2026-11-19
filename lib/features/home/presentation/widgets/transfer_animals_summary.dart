import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:flutter/material.dart';

/// Summary shared by the outgoing transfer and incoming reception screens.
class TransferAnimalsSummary extends StatelessWidget {
  final List<AnimalModel> animals;
  final int? animalCount;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? headerLeading;
  final Widget Function(AnimalModel)? animalBuilder;
  final IconData? expandedIcon;

  const TransferAnimalsSummary({
    super.key,
    required this.animals,
    this.animalCount,
    required this.expanded,
    required this.onToggle,
    this.headerLeading,
    this.animalBuilder,
    this.expandedIcon,
  });

  @override
  Widget build(BuildContext context) {
    if ((animalCount ?? animals.length) == 1 && animals.length == 1) {
      return animalBuilder?.call(animals.single) ??
          TransferAnimalSummaryRow(animal: animals.single);
    }
    return Column(
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: InkWell(
            key: const Key('transfer-animals-toggle'),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: headerLeading == null ? AppSpacing.l : 0,
                end: AppSpacing.l,
                top: AppSpacing.m,
                bottom: AppSpacing.m,
              ),
              child: Row(
                children: [
                  if (headerLeading != null) ...[
                    headerLeading!,
                    const SizedBox(width: AppSpacing.m),
                  ],
                  Expanded(
                    child: Text(
                      'Animales a transferir (${animalCount ?? animals.length})',
                      style: AppTypography.body3,
                    ),
                  ),
                  Icon(
                    expanded
                        ? expandedIcon ?? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    color: AppColors.greyMedio,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: headerLeading == null ? 0 : 36,
          color: AppColors.greyDelineante,
        ),
        if (expanded)
          for (final animal in animals)
            animalBuilder?.call(animal) ??
                TransferAnimalSummaryRow(animal: animal),
      ],
    );
  }
}

class TransferAnimalSummaryRow extends StatelessWidget {
  final AnimalModel animal;
  final Widget? trailing;
  final Widget? leading;
  final String? supplementaryText;
  final String? unknownFamilyIconPath;
  final VoidCallback? onTap;
  final String? detailsText;
  final ValueChanged<String>? onImageError;

  const TransferAnimalSummaryRow({
    super.key,
    required this.animal,
    this.trailing,
    this.leading,
    this.supplementaryText,
    this.unknownFamilyIconPath,
    this.onTap,
    this.detailsText,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    final details =
        detailsText ??
        [
          if (animal.breed?.trim().isNotEmpty ?? false) animal.breed!,
          if (animal.sex?.trim().isNotEmpty ?? false) animal.sexDisplay,
        ].join(' - ');
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            key: ValueKey('transfer-animal-${animal.id}'),
            padding: EdgeInsetsDirectional.only(
              start: leading == null ? AppSpacing.xs : 0,
              end: AppSpacing.xs,
              top: AppSpacing.s,
              bottom: AppSpacing.s,
            ),
            child: Row(
              children: [
                if (leading != null) leading!,
                AnimalAvatar(
                  animal: animal,
                  size: 32,
                  borderRadius: 4,
                  unknownFamilyIconPath: unknownFamilyIconPath,
                  onImageError: onImageError,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: animal.name,
                          style: AppTypography.body3,
                          children: [
                            TextSpan(
                              text: '   ${animal.code}',
                              style: AppTypography.body5.copyWith(
                                color: AppColors.greyMedio,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (animal.ageDisplay.isNotEmpty)
                        Text(
                          animal.ageDisplay,
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyBordes,
                          ),
                        ),
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyBordes,
                          ),
                        ),
                      if (supplementaryText != null)
                        Text(
                          supplementaryText!,
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyBordes,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: leading == null ? 0 : 36,
            color: AppColors.greyDelineante,
          ),
        ],
      ),
    );
  }
}
