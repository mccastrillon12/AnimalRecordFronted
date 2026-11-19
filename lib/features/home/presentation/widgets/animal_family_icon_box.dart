import 'package:animal_record/features/home/presentation/utils/animal_picture.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalFamilyIconBox extends StatelessWidget {
  final String family;
  final Key? boxKey;
  final double size;
  final double iconSize;

  const AnimalFamilyIconBox({
    super.key,
    required this.family,
    this.boxKey,
    this.size = 200,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: boxKey,
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.greyDelineante),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: SvgPicture.asset(
          animalPictureIcon(family: family),
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(
            AppColors.greyBordes,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
