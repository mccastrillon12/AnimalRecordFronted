import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AnimalRecordSortButton extends StatelessWidget {
  final bool sortAscending;
  final VoidCallback onTap;

  const AnimalRecordSortButton({
    super.key,
    required this.sortAscending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorders.small(),
        boxShadow: const [AppShadows.card],
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: AppBorders.small(),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorders.small(),
          child: SizedBox.square(
            dimension: AppSpacing.iconSizeMedium,
            child: Icon(
              Icons.sort_by_alpha_rounded,
              color: AppColors.greyMedio,
              size: 22,
              semanticLabel: sortAscending
                  ? 'Orden ascendente'
                  : 'Orden descendente',
            ),
          ),
        ),
      ),
    );
  }
}
