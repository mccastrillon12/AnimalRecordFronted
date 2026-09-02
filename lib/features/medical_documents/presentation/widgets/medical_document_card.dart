import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class MedicalDocumentCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const MedicalDocumentCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = AppBorders.medium();
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [AppShadows.card],
      ),
      child: Material(
        color: AppColors.bgBlancoAntiFlash,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
      ),
    );
  }
}
