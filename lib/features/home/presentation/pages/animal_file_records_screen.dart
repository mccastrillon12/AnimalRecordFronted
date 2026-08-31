import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_sort_button.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AnimalFileRecordSection { diagnosticImages, laboratoryResults }

class AnimalFileRecordsScreen extends StatefulWidget {
  final AnimalModel animal;
  final AnimalFileRecordSection section;
  final MedicalDocumentThumbnailUriLoader? diagnosticThumbnailUriLoader;

  const AnimalFileRecordsScreen({
    super.key,
    required this.animal,
    required this.section,
    this.diagnosticThumbnailUriLoader,
  });

  @override
  State<AnimalFileRecordsScreen> createState() =>
      _AnimalFileRecordsScreenState();
}

class _AnimalFileRecordsScreenState extends State<AnimalFileRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _sortAscending = true;

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
                  key: const Key('animal-file-records-panel'),
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.l,
                              80,
                              AppSpacing.l,
                              0,
                            ),
                            child: Text(
                              widget.section.title,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.greyTextos,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                                      'animal-file-records-search-field',
                                    ),
                                    fillColor: AppColors.white,
                                    borderColor: AppColors.greyBordes,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                AnimalRecordSortButton(
                                  key: const Key(
                                    'animal-file-records-sort-button',
                                  ),
                                  sortAscending: _sortAscending,
                                  onTap: () => setState(
                                    () => _sortAscending = !_sortAscending,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            key: Key('animal-file-records-list-gap'),
                            height: AppSpacing.l,
                          ),
                          Expanded(
                            child: AnimalMedicalDocumentsView(
                              animalId: widget.animal.id,
                              category: widget.section.category,
                              searchQuery: _searchController.text,
                              documentFilter: (document) =>
                                  document.finalCategory ==
                                  widget.section.category,
                              alphabeticalSortAscending: _sortAscending,
                              emptyTitle: widget.section.emptyTitle,
                              emptyDescription: widget.section.emptyDescription,
                              diagnosticThumbnailUriLoader:
                                  widget.diagnosticThumbnailUriLoader,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: AppSpacing.l,
                        right: AppSpacing.l,
                        child: IconButton(
                          key: const Key('close-animal-file-records'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.greyIconos,
                            size: AppSpacing.iconSizeSmall,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: AppSpacing.iconSizeSmall,
                            height: AppSpacing.iconSizeSmall,
                          ),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.l,
                        bottom: AppSpacing.l,
                        child: AnimalDocumentUploadMenu(
                          animalId: widget.animal.id,
                          requestedCategory: widget.section.category,
                          onUploaded: () => context
                              .read<AnimalMedicalDocumentsCubit>()
                              .refreshAfterUpload(
                                widget.animal.id,
                                category: widget.section.category,
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

extension on AnimalFileRecordSection {
  MedicalDocumentCategory get category => switch (this) {
    AnimalFileRecordSection.diagnosticImages =>
      MedicalDocumentCategory.diagnosticImage,
    AnimalFileRecordSection.laboratoryResults =>
      MedicalDocumentCategory.laboratoryResult,
  };

  String get title => switch (this) {
    AnimalFileRecordSection.diagnosticImages => 'Imágenes diagnósticas',
    AnimalFileRecordSection.laboratoryResults => 'Resultados de laboratorio',
  };

  String get emptyTitle => switch (this) {
    AnimalFileRecordSection.diagnosticImages => 'No hay archivos subidos',
    AnimalFileRecordSection.laboratoryResults =>
      'El registro de resultados de laboratorio está vacío',
  };

  String get emptyDescription => switch (this) {
    AnimalFileRecordSection.diagnosticImages =>
      'Aquí se podrán visualizar las imágenes\n'
          'diagnósticas que se suban.',
    AnimalFileRecordSection.laboratoryResults =>
      'Aquí se podrán visualizar los resultados\n'
          'de laboratorio que se suban.',
  };
}
