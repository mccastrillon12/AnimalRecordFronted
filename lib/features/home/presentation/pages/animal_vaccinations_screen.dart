import 'dart:async';

import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_card_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_sort_button.dart';
import 'package:animal_record/features/home/presentation/widgets/vaccination_groups_view.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
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
  MedicalDocumentAiFeedbackLocalDataSource? _aiFeedbackStore;
  bool _showAiFeedback = false;
  bool _hasAnsweredAiFeedback = false;
  int _aiFeedbackRequestId = 0;

  @override
  void initState() {
    super.initState();
    if (di.sl.isRegistered<MedicalDocumentAiFeedbackLocalDataSource>()) {
      _aiFeedbackStore = di.sl<MedicalDocumentAiFeedbackLocalDataSource>();
      _showAiFeedback = _aiFeedbackStore!.isPending(
        widget.animal.id,
        MedicalDocumentCategory.vaccinationCard,
      );
    }
    _searchController.addListener(_refreshSearch);
  }

  void _refreshSearch() => setState(() {});

  void _handleUploadedDocument() {
    setState(() {
      _showAiFeedback = true;
      _hasAnsweredAiFeedback = false;
      _aiFeedbackRequestId++;
    });
    final store = _aiFeedbackStore;
    if (store != null) unawaited(store.markPending(
      widget.animal.id,
      MedicalDocumentCategory.vaccinationCard,
    ));
    context.read<AnimalMedicalDocumentsCubit>().refreshAfterUpload(
      widget.animal.id,
      category: MedicalDocumentCategory.vaccinationCard,
    );
  }

  Future<void> _markAiFeedbackAnswered() async {
    await _aiFeedbackStore?.clearPending(
      widget.animal.id,
      MedicalDocumentCategory.vaccinationCard,
    );
    if (mounted) setState(() => _hasAnsweredAiFeedback = true);
  }

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
                          const SizedBox(height: AppSpacing.xl),
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
                                AnimalRecordSortButton(
                                  key: const Key('vaccinations-sort-button'),
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
                          const SizedBox(
                            key: Key('vaccinations-list-gap'),
                            height: AppSpacing.l,
                          ),
                          Expanded(
                            child: VaccinationGroupsView(
                              animal: widget.animal,
                              searchQuery: _searchController.text,
                              alphabeticalSortAscending:
                                  _alphabeticalSortAscending,
                              showAiFeedback: _showAiFeedback,
                              aiFeedbackRequestId: _aiFeedbackRequestId,
                              initialAiFeedbackResponded:
                                  _hasAnsweredAiFeedback,
                              onAiFeedbackSubmitted: _markAiFeedbackAnswered,
                              onAiFeedbackDismissed: () => setState(
                                () => _showAiFeedback = false,
                              ),
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
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Ver carné',
                                        style: AppTypography.body4.copyWith(
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
                          onUploaded: _handleUploadedDocument,
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
                const TextSpan(text: ' - '),
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
