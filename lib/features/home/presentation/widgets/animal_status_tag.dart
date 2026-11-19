import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Same measurements as the existing Inactivo tag in lists and detail headers.
class AnimalStatusTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final bool showShadow;
  const AnimalStatusTag({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.showShadow = true,
  });
  factory AnimalStatusTag.pending() => const AnimalStatusTag(
    label: 'Pendiente',
    color: AppColors.greyTextos,
    background: Color(0xFFE8E9EC),
  );
  factory AnimalStatusTag.transferred({bool showShadow = true}) =>
      AnimalStatusTag(
        label: 'Transferido',
        color: Color(0xFF1E91D6),
        background: AppColors.bgHielo,
        showShadow: showShadow,
      );
  factory AnimalStatusTag.inactive({bool showShadow = true}) => AnimalStatusTag(
    label: 'Inactivo',
    color: AppColors.errorRojo,
    background: AppColors.bgRosa,
    showShadow: showShadow,
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ]
          : null,
    ),
    child: Text(label, style: AppTypography.body5.copyWith(color: color)),
  );
}
