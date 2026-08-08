import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalRecordSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Key? fieldKey;
  final Color fillColor;
  final Color borderColor;

  const AnimalRecordSearchField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.fillColor = AppColors.bgBlancoAntiFlash,
    this.borderColor = AppColors.greyDelineante,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: AppBorders.small(),
      borderSide: BorderSide(color: borderColor, width: 1),
    );

    return SizedBox(
      height: AppSpacing.iconSizeMedium,
      child: TextField(
        key: fieldKey,
        controller: controller,
        style: AppTypography.body4,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          isDense: true,
          hintText: 'Buscar',
          hintStyle: AppTypography.body4.copyWith(color: AppColors.greyBordes),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.m, right: 10),
            child: SvgPicture.asset(
              'assets/icons/vuesax-linear-search-2.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.greyBordes,
                BlendMode.srcIn,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}
