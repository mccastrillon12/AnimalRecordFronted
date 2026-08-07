import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalClinicalHistoryScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalClinicalHistoryScreen({super.key, required this.animal});

  @override
  State<AnimalClinicalHistoryScreen> createState() =>
      _AnimalClinicalHistoryScreenState();
}

class _AnimalClinicalHistoryScreenState
    extends State<AnimalClinicalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundDegrade,
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: const SizedBox(height: AppSpacing.l),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorders.radiusXXLarge),
                      topRight: Radius.circular(AppBorders.radiusXXLarge),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _ClinicalHistoryHeader(animal: widget.animal),
                          const SizedBox(
                            key: Key('clinical-history-header-description-gap'),
                            height: AppSpacing.xl,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: Text(
                              'Aquí podrá visualizar los veterinarios que han '
                              'atendido al animal y han creado historias clínicas '
                              'en Animal Record.',
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyTextos,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(
                            key: Key('clinical-history-description-search-gap'),
                            height: AppSpacing.xl,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: _ClinicalHistorySearchField(
                              controller: _searchController,
                            ),
                          ),
                          const SizedBox(
                            key: Key('clinical-history-empty-gap'),
                            height: 100,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: Text(
                              'Ningún veterinario ha creado historias clínicas '
                              'para este animal.',
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyTextos,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Positioned(
                        top: AppSpacing.l,
                        right: AppSpacing.l,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.greyIconos,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.l,
                        bottom: AppSpacing.l,
                        child: AnimalDocumentUploadMenu(
                          animalId: widget.animal.id,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalHistoryHeader extends StatelessWidget {
  final AnimalModel animal;

  const _ClinicalHistoryHeader({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 68, AppSpacing.l, 0),
      child: Column(
        children: [
          Text(
            'Historia clínica',
            style: AppTypography.heading1.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
              children: [
                TextSpan(
                  text: animal.name,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
                const TextSpan(text: '  -  '),
                TextSpan(text: animal.code),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClinicalHistorySearchField extends StatelessWidget {
  final TextEditingController controller;

  const _ClinicalHistorySearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.iconSizeMedium,
      child: TextField(
        key: const Key('clinical-history-search-field'),
        controller: controller,
        style: AppTypography.body4,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.bgBlancoAntiFlash,
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
          border: OutlineInputBorder(
            borderRadius: AppBorders.small(),
            borderSide: const BorderSide(
              color: AppColors.greyDelineante,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorders.small(),
            borderSide: const BorderSide(
              color: AppColors.greyDelineante,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorders.small(),
            borderSide: const BorderSide(
              color: AppColors.greyDelineante,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}
