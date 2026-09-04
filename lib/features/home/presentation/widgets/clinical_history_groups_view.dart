import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/display/app_user_avatar.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_document_upload_menu.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_ai_feedback_banner.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/usecases/export_shared_file_analysis_pdf_usecase.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClinicalHistoryGroupsView extends StatelessWidget {
  final AnimalModel animal;
  final String searchQuery;
  final bool showAiFeedback;
  final int aiFeedbackRequestId;
  final bool initialAiFeedbackResponded;
  final VoidCallback? onAiFeedbackDismissed;
  final Future<void> Function()? onAiFeedbackSubmitted;

  const ClinicalHistoryGroupsView({
    super.key,
    required this.animal,
    this.searchQuery = '',
    this.showAiFeedback = false,
    this.aiFeedbackRequestId = 0,
    this.initialAiFeedbackResponded = false,
    this.onAiFeedbackDismissed,
    this.onAiFeedbackSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AnimalMedicalDocumentsCubit,
      AnimalMedicalDocumentsState
    >(
      builder: (context, state) {
        if (state is AnimalMedicalDocumentsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryFrances),
          );
        }
        if (state is AnimalMedicalDocumentsError) {
          return Center(
            child: TextButton(
              onPressed: () => context.read<AnimalMedicalDocumentsCubit>().load(
                animal.id,
                category: MedicalDocumentCategory.clinicalHistory,
              ),
              child: const Text('Reintentar'),
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != MedicalDocumentCategory.clinicalHistory) {
          return const SizedBox.shrink();
        }

        final query = searchQuery.trim().toLowerCase();
        final currentUser = _currentUser(context);
        final allGroups = _groups(
          state.documents,
          currentUserName: currentUser.name.isNotEmpty
              ? currentUser.name
              : (animal.ownerName?.trim().isNotEmpty == true
                    ? animal.ownerName!.trim()
                    : 'Usuario'),
          currentUserPicture: currentUser.picture,
        );
        final shouldShowAiFeedback = showAiFeedback && allGroups.isNotEmpty;
        if (allGroups.isEmpty && !shouldShowAiFeedback) {
          return const _ClinicalHistoryEmptyState();
        }
        final groups = allGroups
            .where(
              (group) =>
                  query.isEmpty ||
                  group.searchText.toLowerCase().contains(query),
            )
            .toList(growable: false);
        if (groups.isEmpty && !shouldShowAiFeedback) {
          return const _ClinicalHistoryNoResultsState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            88,
          ),
          itemCount: groups.length + (shouldShowAiFeedback ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            if (shouldShowAiFeedback && index == 0) {
              return MedicalDocumentAiFeedbackBanner(
                key: ValueKey(aiFeedbackRequestId),
                initialHasResponded: initialAiFeedbackResponded,
                onDismissed: onAiFeedbackDismissed,
                onSubmitted: onAiFeedbackSubmitted,
              );
            }
            final group = groups[index - (shouldShowAiFeedback ? 1 : 0)];
            return _ClinicalHistoryGroupCard(
              group: group,
              onTap: () {
                final singleDocument = group.documents.length == 1
                    ? group.documents.single
                    : null;
                final destination = singleDocument?.validatedExtraction != null
                    ? ClinicalHistoryDocumentScreen(document: singleDocument!)
                    : ClinicalHistoryGroupScreen(animal: animal, group: group);
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => destination),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ClinicalHistoryGroupScreen extends StatefulWidget {
  final AnimalModel animal;
  final ClinicalHistoryGroup group;

  const ClinicalHistoryGroupScreen({
    super.key,
    required this.animal,
    required this.group,
  });

  @override
  State<ClinicalHistoryGroupScreen> createState() =>
      _ClinicalHistoryGroupScreenState();
}

class ClinicalHistoryDocumentScreen extends StatefulWidget {
  final MedicalDocumentEntity document;

  const ClinicalHistoryDocumentScreen({super.key, required this.document});

  @override
  State<ClinicalHistoryDocumentScreen> createState() =>
      _ClinicalHistoryDocumentScreenState();
}

class _ClinicalHistoryDocumentScreenState
    extends State<ClinicalHistoryDocumentScreen> {
  final _closeIconKey = GlobalKey();
  final _actionIconKey = GlobalKey();
  late Future<SharedFileAnalysisEntity> _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = di.sl<MedicalDocumentAnalysisPresenter>().forAccepted(
      widget.document,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedFileAnalysisEntity>(
      future: _analysis,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final analysis = snapshot.data;
        if (analysis == null) {
          return _MedicalCatalogError(
            onRetry: () => setState(() {
              _analysis = di.sl<MedicalDocumentAnalysisPresenter>().forAccepted(
                widget.document,
              );
            }),
          );
        }
        return SharedFileSendScreen(
          analysis: analysis,
          closeIconKey: _closeIconKey,
          actionIconKey: _actionIconKey,
          onViewOriginal: () => _showOriginal(context),
          resolveOriginalUri: () =>
              di.sl<GetMedicalDocumentDownloadUriUseCase>()(widget.document.id),
          actionLabel: medicalDocumentSendActionLabel(
            MedicalDocumentCategory.clinicalHistory,
          ),
        );
      },
    );
  }

  Future<void> _showOriginal(BuildContext context) async {
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: di.sl<GetMedicalDocumentDownloadUriUseCase>(),
      saveOriginalUseCase: di.sl<SaveMedicalDocumentOriginalUseCase>(),
    );
    await preview.show(
      context,
      acceptedDocumentId: widget.document.id,
      fileName: widget.document.originalFileName,
      mimeType: widget.document.mimeType,
      closeIconKey: _closeIconKey,
      downloadIconKey: _actionIconKey,
    );
  }
}

class _ClinicalHistoryGroupScreenState
    extends State<ClinicalHistoryGroupScreen> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundDegrade),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.l,
                            AppSpacing.xl,
                            AppSpacing.l,
                            0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                key: const Key('clinical-history-group-back'),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                color: AppColors.greyIconos,
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                color: AppColors.greyIconos,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _GroupHeading(
                          group: widget.group,
                          animal: widget.animal,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                          ),
                          child: Text(
                            'Encuentre todas las historias clínicas realizadas por '
                            'el veterinario seleccionado.',
                            style: AppTypography.body4.copyWith(
                              color: AppColors.greyTextos,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: const Key('download-all-clinical-histories'),
                              onPressed: _downloading ? null : _downloadAll,
                              icon: _downloading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      AppIcons.receiveSquare,
                                      width: 20,
                                      height: 20,
                                    ),
                              label: const Text('Descargar todo'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.l,
                              AppSpacing.xs,
                              AppSpacing.l,
                              88,
                            ),
                            itemCount: widget.group.documents.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.m),
                            itemBuilder: (context, index) =>
                                _ClinicalHistoryCard(
                                  index: index,
                                  document: widget.group.documents[index],
                                  onTap: () => _showDocument(
                                    widget.group.documents[index],
                                  ),
                                  onDownload: () => _downloadDocument(
                                    widget.group.documents[index],
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: AppSpacing.l,
                      bottom: AppSpacing.l,
                      child: AnimalDocumentUploadMenu(
                        animalId: widget.animal.id,
                        requestedCategory:
                            MedicalDocumentCategory.clinicalHistory,
                        onUploaded: () =>
                            context.read<AnimalMedicalDocumentsCubit>().load(
                              widget.animal.id,
                              category: MedicalDocumentCategory.clinicalHistory,
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
    );
  }

  Future<void> _downloadAll() async {
    setState(() => _downloading = true);
    try {
      final downloadUri = di.sl<GetMedicalDocumentDownloadUriUseCase>();
      final analyses = await Future.wait(
        widget.group.documents
            .where((document) => document.validatedExtraction != null)
            .map((document) async {
              final uri = await downloadUri(document.id);
              final analysis = await di
                  .sl<MedicalDocumentAnalysisPresenter>()
                  .forAccepted(document);
              return analysis.withOriginalUrl(uri.toString());
            }),
      );
      final saved = await di.sl<SaveSharedFileAnalysesPdfUseCase>()(
        analyses,
        fileName: 'historias_clinicas_${widget.animal.name}',
      );
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historias clínicas descargadas.')),
        );
      }
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _downloadDocument(MedicalDocumentEntity document) async {
    if (document.validatedExtraction == null) return;
    try {
      final uri = await di.sl<GetMedicalDocumentDownloadUriUseCase>()(
        document.id,
      );
      final analysis =
          (await di.sl<MedicalDocumentAnalysisPresenter>().forAccepted(
            document,
          )).withOriginalUrl(uri.toString());
      await di.sl<SaveSharedFileAnalysesPdfUseCase>()([
        analysis,
      ], fileName: 'historia_clinica_${widget.animal.name}');
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    }
  }

  Future<void> _showDocument(MedicalDocumentEntity document) async {
    if (document.validatedExtraction == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicalHistoryDocumentScreen(document: document),
      ),
    );
  }
}

class _MedicalCatalogError extends StatelessWidget {
  final VoidCallback onRetry;

  const _MedicalCatalogError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No pudimos cargar los campos del documento.'),
            const SizedBox(height: AppSpacing.m),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class ClinicalHistoryGroup {
  final String name;
  final String clinic;
  final String? profilePicture;
  final bool isCurrentUser;
  final List<MedicalDocumentEntity> documents;

  const ClinicalHistoryGroup({
    required this.name,
    required this.clinic,
    this.profilePicture,
    required this.isCurrentUser,
    required this.documents,
  });

  String get searchText => [
    name,
    clinic,
    for (final document in documents) document.originalFileName,
  ].join(' ');
}

class _ClinicalHistoryGroupCard extends StatelessWidget {
  final ClinicalHistoryGroup group;
  final VoidCallback onTap;

  const _ClinicalHistoryGroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = group.documents.first;
    final borderRadius = AppBorders.small();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('clinical-history-group-${group.name}'),
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.bgBlancoAntiFlash,
            borderRadius: borderRadius,
            boxShadow: const [AppShadows.card],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppUserAvatar(
                    name: group.name,
                    imageUrl: group.profilePicture,
                    size: AppSpacing.xl,
                    borderRadius: AppBorders.radiusSmall,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: AppTypography.body3.copyWith(
                            color: AppColors.greyTextos,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        _GroupValue(
                          label: 'Última actualización:',
                          value: _documentDate(latest),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _GroupValue(
                          label: 'Archivos:',
                          value: '${group.documents.length}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    key: Key('clinical-history-document-count-${group.name}'),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${group.documents.length}',
                      style: AppTypography.body6.copyWith(
                        color: AppColors.primaryFrances,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  key: Key('view-clinical-histories-${group.name}'),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver historias',
                        style: AppTypography.body3.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.greyIconos,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalHistoryCard extends StatelessWidget {
  final int index;
  final MedicalDocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _ClinicalHistoryCard({
    required this.index,
    required this.document,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalDocumentCard(
      key: Key('clinical-history-shadow-${document.id}'),
      interactionKey: Key('clinical-history-${document.id}'),
      onTap: onTap,
      borderRadius: AppBorders.large(),
      headerCrossAxisAlignment: CrossAxisAlignment.center,
      trailingSpacing: 0,
      leading: SvgPicture.asset(
        AppIcons.folderFavorite,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryAzulClaro,
          BlendMode.srcIn,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historia clínica ${index + 1}',
            style: AppTypography.body3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _documentDate(document),
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
        ],
      ),
      trailing: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: PopupMenuButton<String>(
          key: Key('clinical-history-menu-${document.id}'),
          padding: EdgeInsets.zero,
          offset: const Offset(-175, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
          ),
          constraints: const BoxConstraints(minWidth: 203, maxWidth: 203),
          color: AppColors.white,
          elevation: 4,
          icon: const Icon(Icons.more_vert, color: AppColors.primaryFrances),
          onSelected: (_) => onDownload(),
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'download',
              height: 47,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.receiveSquare,
                    width: AppSpacing.iconSizeSmall,
                    height: AppSpacing.iconSizeSmall,
                    colorFilter: const ColorFilter.mode(
                      AppColors.greyMedio,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Descargar historia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body4.copyWith(
                        color: AppColors.greyTextos,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  final ClinicalHistoryGroup group;
  final AnimalModel animal;

  const _GroupHeading({required this.group, required this.animal});

  @override
  Widget build(BuildContext context) {
    final title = group.isCurrentUser ? 'Subidas por mí' : group.name;
    return Column(
      children: [
        Text.rich(
          TextSpan(
            style: AppTypography.heading1.copyWith(
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(text: title),
              if (!group.isCurrentUser && group.clinic.isNotEmpty)
                TextSpan(
                  text: ' - ${group.clinic}',
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
            ],
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
              TextSpan(text: ' - ${animal.code}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupValue extends StatelessWidget {
  final String label;
  final String value;

  const _GroupValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 128,
          child: Text(
            label,
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
          ),
        ),
      ],
    );
  }
}

class _ClinicalHistoryEmptyState extends StatelessWidget {
  const _ClinicalHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El registro de historias clínicas está vacío',
              style: AppTypography.body3.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Aquí se podrán visualizar las historias clínicas que se creen.',
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalHistoryNoResultsState extends StatelessWidget {
  const _ClinicalHistoryNoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
        child: Text(
          'No se encontraron historias clínicas.',
          style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

List<ClinicalHistoryGroup> _groups(
  List<MedicalDocumentEntity> documents, {
  required String currentUserName,
  required String? currentUserPicture,
}) {
  final values = <String, List<MedicalDocumentEntity>>{};
  final metadata =
      <String, ({String name, String clinic, bool isCurrentUser})>{};
  for (final document in documents) {
    final name = currentUserName;
    const clinic = '';
    const isCurrentUser = true;
    final key = '${name.toLowerCase()}|${clinic.toLowerCase()}';
    values.putIfAbsent(key, () => []).add(document);
    metadata[key] = (name: name, clinic: clinic, isCurrentUser: isCurrentUser);
  }
  return values.entries
      .map((entry) {
        final sorted = [...entry.value]
          ..sort(
            (left, right) =>
                _documentTimestamp(right).compareTo(_documentTimestamp(left)),
          );
        final value = metadata[entry.key]!;
        return ClinicalHistoryGroup(
          name: value.name,
          clinic: value.clinic,
          profilePicture: value.isCurrentUser ? currentUserPicture : null,
          isCurrentUser: value.isCurrentUser,
          documents: sorted,
        );
      })
      .toList(growable: false);
}

({String name, String? picture}) _currentUser(BuildContext context) {
  try {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      return (name: state.user.name, picture: state.user.profilePicture);
    }
  } catch (_) {}
  return (name: '', picture: null);
}

DateTime _documentTimestamp(MedicalDocumentEntity document) {
  return document.updatedAt ??
      document.reviewedAt ??
      document.createdAt ??
      parseMedicalDocumentDate(document.validatedExtraction?.documentDate) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _documentDate(MedicalDocumentEntity document) {
  final backendDate = displayMedicalDocumentDate(
    document.validatedExtraction?.documentDate,
  );
  if (backendDate.isNotEmpty) return backendDate;
  final date = _documentTimestamp(document);
  if (date.millisecondsSinceEpoch == 0) return '';
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
