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
          _familyIconPath(family),
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

String _familyIconPath(String family) {
  final lowerFamily = family.toLowerCase();
  if (lowerFamily.contains('felino') || lowerFamily.contains('gato')) {
    return 'assets/illustrations/cat_icon.svg';
  }
  if (lowerFamily.contains('canino') || lowerFamily.contains('perro')) {
    return 'assets/illustrations/dog_icon.svg';
  }
  if (lowerFamily.contains('bovino') || lowerFamily.contains('vaca')) {
    return 'assets/illustrations/bovino_icon.svg';
  }
  if (lowerFamily.contains('equino') || lowerFamily.contains('caballo')) {
    return 'assets/illustrations/equino_icon.svg';
  }
  return 'assets/illustrations/dog_icon.svg';
}
