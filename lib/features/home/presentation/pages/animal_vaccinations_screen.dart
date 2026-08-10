import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_card_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/vaccination_groups_view.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

class AnimalVaccinationsScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalVaccinationsScreen({super.key, required this.animal});

  @override
  State<AnimalVaccinationsScreen> createState() =>
      _AnimalVaccinationsScreenState();
}

class _AnimalVaccinationsScreenState extends State<AnimalVaccinationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool? _alphabeticalSortAscending;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  void _refreshSearch() => setState(() {});

  @override
  void dispose() {
    _searchController.removeListener(_refreshSearch);
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
                  key: const Key('vaccinations-panel'),
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
                          _VaccinationsHeader(animal: widget.animal),
                          const SizedBox(height: AppSpacing.l),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AnimalRecordSearchField(
                                    controller: _searchController,
                                    fieldKey: const Key(
                                      'vaccinations-search-field',
                                    ),
                                    fillColor: AppColors.white,
                                    borderColor: AppColors.greyBordes,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                _VaccinationSortButton(
                                  sortAscending:
                                      _alphabeticalSortAscending ?? true,
                                  onTap: () => setState(() {
                                    _alphabeticalSortAscending =
                                        _alphabeticalSortAscending == null
                                        ? true
                                        : !_alphabeticalSortAscending!;
                                  }),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: VaccinationGroupsView(
                              animal: widget.animal,
                              searchQuery: _searchController.text,
                              alphabeticalSortAscending:
                                  _alphabeticalSortAscending,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: AppSpacing.l,
                        left: AppSpacing.l,
                        right: AppSpacing.l,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Semantics(
                              button: true,
                              label: 'Ver carné de vacunas',
                              child: GestureDetector(
                                key: const Key('view-vaccination-card-button'),
                                onTap: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context
                                          .read<AnimalMedicalDocumentsCubit>(),
                                      child: VaccinationCardScreen(
                                        animal: widget.animal,
                                      ),
                                    ),
                                  ),
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  height: AppSpacing.iconSizeSmall,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: AppColors.greyMedio,
                                        size: 16,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Ver carné',
                                        style: AppTypography.body6.copyWith(
                                          color: AppColors.greyMedio,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('close-vaccinations-button'),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.greyIconos,
                              ),
                              iconSize: AppSpacing.iconSizeSmall,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: AppSpacing.iconSizeSmall,
                                height: AppSpacing.iconSizeSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.l,
                        bottom: AppSpacing.l,
                        child: AnimalDocumentUploadMenu(
                          animalId: widget.animal.id,
                          requestedCategory:
                              MedicalDocumentCategory.vaccinationCard,
                          onUploaded: () => context
                              .read<AnimalMedicalDocumentsCubit>()
                              .refreshAfterUpload(
                                widget.animal.id,
                                category:
                                    MedicalDocumentCategory.vaccinationCard,
                              ),
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

class _VaccinationsHeader extends StatelessWidget {
  final AnimalModel animal;

  const _VaccinationsHeader({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 80, AppSpacing.l, 0),
      child: Column(
        children: [
          Text(
            key: const Key('vaccinations-title'),
            'Carné de vacunas',
            style: AppTypography.body1.copyWith(color: AppColors.greyTextos),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Verifica que las vacunas estén al día',
            style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            key: const Key('vaccinations-animal-identification'),
            TextSpan(
              style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
              children: [
                TextSpan(
                  text: animal.name,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
                const TextSpan(text: '  -  '),
                TextSpan(text: animal.code),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VaccinationSortButton extends StatelessWidget {
  final bool sortAscending;
  final VoidCallback onTap;

  const _VaccinationSortButton({
    required this.sortAscending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppBorders.small(),
      elevation: 2,
      shadowColor: AppColors.greyNegro.withValues(alpha: 0.12),
      child: InkWell(
        key: const Key('vaccinations-sort-button'),
        onTap: onTap,
        borderRadius: AppBorders.small(),
        child: SizedBox(
          width: AppSpacing.iconSizeMedium,
          height: AppSpacing.iconSizeMedium,
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
    );
  }
}
