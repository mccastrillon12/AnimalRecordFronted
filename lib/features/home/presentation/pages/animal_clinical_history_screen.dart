import 'dart:async';

import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/clinical_history_groups_view.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

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
        MedicalDocumentCategory.clinicalHistory,
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
      MedicalDocumentCategory.clinicalHistory,
    ));
    context.read<AnimalMedicalDocumentsCubit>().load(
      widget.animal.id,
      category: MedicalDocumentCategory.clinicalHistory,
    );
  }

  Future<void> _markAiFeedbackAnswered() async {
    await _aiFeedbackStore?.clearPending(
      widget.animal.id,
      MedicalDocumentCategory.clinicalHistory,
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
    return _buildOverview(context);
  }

  Widget _buildOverview(BuildContext context) {
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
                            child:
                                BlocSelector<
                                  AnimalMedicalDocumentsCubit,
                                  AnimalMedicalDocumentsState,
                                  bool
                                >(
                                  selector: (state) =>
                                      state is AnimalMedicalDocumentsLoaded &&
                                      state.category ==
                                          MedicalDocumentCategory
                                              .clinicalHistory &&
                                      state.documents.isNotEmpty,
                                  builder: (context, hasRecords) =>
                                      AnimalRecordSearchField(
                                        controller: _searchController,
                                        enabled: hasRecords,
                                        fieldKey: const Key(
                                          'clinical-history-search-field',
                                        ),
                                        maxLength: 20,
                                      ),
                                ),
                          ),
                          Expanded(
                            child: ClinicalHistoryGroupsView(
                              animal: widget.animal,
                              searchQuery: _searchController.text,
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
                          requestedCategory:
                              MedicalDocumentCategory.clinicalHistory,
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
            'Historias clínicas',
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
