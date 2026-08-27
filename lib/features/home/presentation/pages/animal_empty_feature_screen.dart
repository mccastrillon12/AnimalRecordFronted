import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_family_icon_box.dart';

class AnimalEmptyFeatureScreen extends StatelessWidget {
  final String title;
  final String mainText;
  final String subText;
  final String animalFamily;
  final VoidCallback? onContinue;

  const AnimalEmptyFeatureScreen({
    super.key,
    required this.title,
    required this.mainText,
    required this.subText,
    required this.animalFamily,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ModalPageLayout(
      title: title,
      backgroundColor: AppColors.bgBlancoAntiFlash,
      bottomSafeAreaColor: AppColors.bgBlancoAntiFlash,
      titlePadding: const EdgeInsets.only(top: 96, bottom: 0),
      fixedTitle: true,
      fixedHeaderHeight: 120,
      onClose: () => Navigator.of(context).pop(),
      bottomChild: CustomButton(
        text: 'Continuar',
        onPressed: onContinue ?? () => Navigator.of(context).pop(),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),
          AnimalFamilyIconBox(
            family: animalFamily,
            boxKey: const Key('animal-empty-feature-placeholder'),
          ),
          const SizedBox(
            key: Key('animal-empty-feature-content-gap'),
            height: 48,
          ),
          _EmptyFeatureCopy(mainText: mainText, subText: subText),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EmptyFeatureCopy extends StatelessWidget {
  final String mainText;
  final String subText;

  const _EmptyFeatureCopy({required this.mainText, required this.subText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        key: const Key('animal-empty-feature-copy'),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            Text(
              mainText,
              style: AppTypography.body3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              key: Key('animal-empty-feature-text-gap'),
              height: 16,
            ),
            Text(
              subText,
              style: AppTypography.body4,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
