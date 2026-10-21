import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnalysisAiNotice extends StatelessWidget {
  static const double sendHeight = 68;

  const AnalysisAiNotice({super.key, this.height = sendHeight});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.small(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(AppIcons.magicStar, width: 12, height: 12),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body6.copyWith(
                  color: AppColors.greyNegro,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Análisis realizado con IA. '),
                  TextSpan(
                    text: 'Verifica siempre los datos con el archivo original.',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegro,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
