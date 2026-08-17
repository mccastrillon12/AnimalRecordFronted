import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_list_control_button.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/diagnostic_aid_folders_view.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalDiagnosticAidsScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalDiagnosticAidsScreen({super.key, required this.animal});

  @override
  State<AnimalDiagnosticAidsScreen> createState() =>
      _AnimalDiagnosticAidsScreenState();
}

class _AnimalDiagnosticAidsScreenState
    extends State<AnimalDiagnosticAidsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _closeIconKey = GlobalKey();
  bool _ascending = false;

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
                  key: const Key('diagnostic-aids-panel'),
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
                              68,
                              AppSpacing.l,
                              0,
                            ),
                            child: Text(
                              'Ayudas diagnósticas',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child:
                                BlocSelector<
                                  AnimalMedicalDocumentsCubit,
                                  AnimalMedicalDocumentsState,
                                  bool
                                >(
                                  selector: (state) =>
                                      state is AnimalMedicalDocumentsLoaded &&
                                      state.category ==
                                          MedicalDocumentCategory.other &&
                                      state.documents.isNotEmpty,
                                  builder: (context, hasRecords) =>
                                      AnimalRecordSearchField(
                                        controller: _searchController,
                                        enabled: hasRecords,
                                        fieldKey: const Key(
                                          'diagnostic-aids-search-field',
                                        ),
                                      ),
                                ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppDropdown<String>(
                                    key: const Key(
                                      'diagnostic-aids-sort-dropdown',
                                    ),
                                    label: '',
                                    hint: 'Última modificación',
                                    value: 'Última modificación',
                                    items: const ['Última modificación'],
                                    itemAsString: (value) => value,
                                    onChanged: (_) {},
                                    showClearOption: false,
                                    preserveOrder: true,
                                    pushContent: false,
                                    width: 148,
                                    height: 40,
                                    triggerBuilder: (_) => Text(
                                      'Última modificación',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body4.copyWith(
                                        color: AppColors.greyTextos,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s),
                                  AnimalListControlButton(
                                    buttonKey: const Key(
                                      'diagnostic-aids-sort-direction',
                                    ),
                                    onTap: () => setState(
                                      () => _ascending = !_ascending,
                                    ),
                                    child: Transform.flip(
                                      flipY: _ascending,
                                      child: SvgPicture.asset(
                                        'assets/icons/Grupo 19427.svg',
                                        key: const Key(
                                          'diagnostic-aids-sort-icon',
                                        ),
                                        width: AppSpacing.iconSizeSmall,
                                        height: AppSpacing.iconSizeSmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Expanded(
                            child: DiagnosticAidFoldersView(
                              animalId: widget.animal.id,
                              query: _searchController.text,
                              ascending: _ascending,
                              closeIconKey: _closeIconKey,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: AppSpacing.l,
                        right: AppSpacing.l,
                        child: IconButton(
                          key: const Key('close-diagnostic-aids-button'),
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            key: _closeIconKey,
                            Icons.close,
                            size: 20,
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
                          requestedCategory: MedicalDocumentCategory.other,
                          onUploaded: () => context
                              .read<AnimalMedicalDocumentsCubit>()
                              .refreshAfterUpload(
                                widget.animal.id,
                                category: MedicalDocumentCategory.other,
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
