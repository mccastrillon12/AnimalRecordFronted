import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:flutter/material.dart';

/// Read-only summary: expanding never changes the animals chosen at entry.
class TransferAnimalsSummary extends StatelessWidget {
  final List<AnimalModel> animals;
  final bool expanded;
  final VoidCallback onToggle;

  const TransferAnimalsSummary({
    super.key,
    required this.animals,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (animals.length == 1) return _AnimalRow(animal: animals.single);
    return Column(
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: InkWell(
            key: const Key('transfer-animals-toggle'),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.m,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Animales a transferir (${animals.length})',
                      style: AppTypography.body3,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: AppColors.greyMedio,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.greyDelineante),
        if (expanded)
          for (final animal in animals) _AnimalRow(animal: animal),
      ],
    );
  }
}

class _AnimalRow extends StatelessWidget {
  final AnimalModel animal;

  const _AnimalRow({required this.animal});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (animal.breed?.trim().isNotEmpty ?? false) animal.breed!,
      if (animal.sex?.trim().isNotEmpty ?? false) animal.sexDisplay,
    ].join(' - ');
    return Container(
      key: ValueKey('transfer-animal-${animal.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.s,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.greyDelineante)),
      ),
      child: Row(
        children: [
          AnimalAvatar(animal: animal, size: 32, borderRadius: 4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
