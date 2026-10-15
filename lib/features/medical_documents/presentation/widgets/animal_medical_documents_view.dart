import 'dart:async';

import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/feedback/app_loading_overlay.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/widgets/menus/app_popup_action_menu.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/medical_document_detail_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_app_profile_mapper.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_ai_feedback_banner.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:animal_record/features/shared_files/presentation/navigation/shared_file_upload_arguments.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalMedicalDocumentsView extends StatelessWidget {
  final String animalId;
  final AnimalModel? animal;
  final MedicalDocumentCategory category;
  final String emptyTitle;
  final String emptyDescription;
  final String searchQuery;
  final bool Function(MedicalDocumentEntity document)? documentFilter;
  final bool? alphabeticalSortAscending;
  final double emptyBottomOffset;
  final bool showAiFeedback;
  final int aiFeedbackRequestId;
  final VoidCallback? onAiFeedbackDismissed;
  final Future<void> Function(MedicalDocumentAiFeedback feedback)? onAiFeedback;
  final bool initialAiFeedbackResponded;
  final Future<void> Function()? onAiFeedbackSubmitted;

  const AnimalMedicalDocumentsView({
    super.key,
    required this.animalId,
    this.animal,
    required this.category,
    required this.emptyTitle,
    required this.emptyDescription,
    this.searchQuery = '',
    this.documentFilter,
    this.alphabeticalSortAscending,
    this.emptyBottomOffset = 100,
    this.showAiFeedback = false,
    this.aiFeedbackRequestId = 0,
    this.onAiFeedbackDismissed,
    this.onAiFeedback,
    this.initialAiFeedbackResponded = false,
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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTypography.body4,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextButton(
                    onPressed: () => context
                        .read<AnimalMedicalDocumentsCubit>()
                        .load(animalId, category: category),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != category) {
          return const SizedBox.shrink();
        }

        final query = searchQuery.trim().toLowerCase();
        final documents = state.documents
            .where((document) => documentFilter?.call(document) ?? true)
            .where(
              (document) =>
                  query.isEmpty ||
                  _searchableDocumentText(document).contains(query),
            )
            .toList();
        if (alphabeticalSortAscending case final ascending?) {
          documents.sort((left, right) {
            final comparison = left.originalFileName.toLowerCase().compareTo(
              right.originalFileName.toLowerCase(),
            );
            return ascending ? comparison : -comparison;
          });
        }
        final shouldShowAiFeedback = showAiFeedback && documents.isNotEmpty;
        final appProfile = animal == null
            ? sharedFileAppProfileByAnimalId(context, animalId)
            : sharedFileAppProfile(context, animal!);
        final aiFeedbackBanner = shouldShowAiFeedback
            ? MedicalDocumentAiFeedbackBanner(
                key: ValueKey(aiFeedbackRequestId),
                onDismissed: onAiFeedbackDismissed,
                onSubmit: onAiFeedback ?? _submitAiFeedback,
                initialHasResponded: initialAiFeedbackResponded,
                onSubmitted: onAiFeedbackSubmitted,
              )
            : null;
        if (documents.isEmpty && !shouldShowAiFeedback) {
          return _EmptyState(
            title: emptyTitle,
            description: emptyDescription,
            bottomOffset: emptyBottomOffset,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          itemCount: documents.length + (shouldShowAiFeedback ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            if (shouldShowAiFeedback && index == 0) return aiFeedbackBanner!;

            final document = documents[index - (shouldShowAiFeedback ? 1 : 0)];
            final documentCategory = document.finalCategory ?? category;
            return MedicalDocumentSummaryCard(
              key: ValueKey('medical-document-summary-${document.id}'),
              document: document,
              category: documentCategory,
              trailing: MedicalDocumentActionsMenu(
                key: ValueKey('medical-document-actions-${document.id}'),
                animalId: animalId,
                document: document,
                category: documentCategory,
              ),
              trailingSpacing: 0,
              onDetail: document.validatedExtraction == null
                  ? null
                  : () => showMedicalDocumentDetail(
                      context,
                      animalId: animalId,
                      document: document,
                      category: documentCategory,
                      appProfile: appProfile,
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitAiFeedback(MedicalDocumentAiFeedback feedback) =>
      di.sl<SubmitMedicalDocumentAiFeedbackUseCase>()(feedback);
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final double bottomOffset;

  const _EmptyState({
    required this.title,
    required this.description,
    required this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          bottomOffset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.body3.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              description,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalDocumentSummaryValue {
  final String label;
  final String value;
  final int maxLines;
  final double spacing;

  const MedicalDocumentSummaryValue({
    required this.label,
    required this.value,
    this.maxLines = 2,
    this.spacing = 0,
  });
}

class MedicalDocumentSummaryCard extends StatelessWidget {
  final MedicalDocumentEntity document;
  final MedicalDocumentCategory category;
  final bool showDescription;
  final String? titleText;
  final int? titleMaxLines;
  final Widget? trailing;
  final double trailingSpacing;
  final List<MedicalDocumentSummaryValue>? values;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;
  final Key? cardKey;
  final Key? detailKey;

  const MedicalDocumentSummaryCard({
    super.key,
    required this.document,
    required this.category,
    this.showDescription = true,
    this.titleText,
    this.titleMaxLines,
    this.trailing,
    this.trailingSpacing = AppSpacing.s,
    this.values,
    this.onTap,
    this.onDetail,
    this.cardKey,
    this.detailKey,
  });

  @override
  Widget build(BuildContext context) {
    final extraction = document.validatedExtraction;
    final date = displayMedicalDocumentShortDate(extraction?.documentDate);
    final description = showDescription ? document.description.trim() : '';
    final number = _documentNumber(document);
    final defaultTitle = [
      'Adjunto: ${document.finalCategory?.label ?? 'Archivo médico'}',
      if (number.isNotEmpty) number,
    ].join(' ');
    final summaryValues =
        values ??
        [
          if (date.isNotEmpty)
            MedicalDocumentSummaryValue(label: 'Fecha:', value: date),
          if (document.originalFileName.trim().isNotEmpty)
            MedicalDocumentSummaryValue(
              label: 'Archivo:',
              value: document.originalFileName,
            ),
          if (description.isNotEmpty)
            MedicalDocumentSummaryValue(
              label: 'Descripción:',
              value: description,
            ),
        ];
    final detailAction =
        onDetail ??
        (extraction == null
            ? null
            : () => showMedicalDocumentDetail(
                context,
                document: document,
                category: category,
              ));
    return MedicalDocumentCard(
      key: cardKey ?? Key('medical-document-card-${document.id}'),
      onTap: onTap ?? detailAction,
      leading: SvgPicture.asset(
        AppIcons.documentUpload,
        key: Key('medical-document-card-icon-${document.id}'),
        width: AppSpacing.iconSizeSmall,
        height: AppSpacing.iconSizeSmall,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryAzulClaro,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        titleText ?? defaultTitle,
        maxLines: titleMaxLines,
        softWrap: titleMaxLines == 1 ? false : null,
        overflow: titleMaxLines == null ? null : TextOverflow.ellipsis,
        style: AppTypography.body3.copyWith(color: AppColors.greyTextos),
      ),
      trailing: trailing,
      trailingSpacing: trailingSpacing,
      headerCrossAxisAlignment: CrossAxisAlignment.center,
      body: summaryValues.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.iconSizeSmall + AppSpacing.m,
              ),
              child: Column(
                children: [
                  for (final value in summaryValues)
                    _DocumentCardValue(
                      label: value.label,
                      value: value.value,
                      maxLines: value.maxLines,
                      spacing: value.spacing,
                    ),
                ],
              ),
            )
          : null,
      footer: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          key: detailKey ?? Key('medical-document-detail-${document.id}'),
          onTap: detailAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver detalle',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyMedio,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SvgPicture.asset(
                  AppIcons.arrowRight,
                  width: AppSpacing.iconSizeSmall,
                  height: AppSpacing.iconSizeSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _medicalDocumentEditingWindow = Duration(hours: 48);
const _medicalDocumentUploadFailureMessage =
    'No fue posible subir el documento. Inténtalo nuevamente.';
const _medicalDocumentEditingExpiredMessage =
    'El tiempo disponible para editar este archivo ya finalizó.';

DateTime? _medicalDocumentEditingDeadline(MedicalDocumentEntity document) {
  final updatedAt = document.updatedAt;
  if (updatedAt != null) return updatedAt.add(_medicalDocumentEditingWindow);
  return document.replacementDeadline;
}

bool _hasActiveMedicalDocumentEditingWindow(
  MedicalDocumentEntity document, {
  DateTime? now,
}) {
  final deadline = _medicalDocumentEditingDeadline(document);
  return document.canReplace &&
      deadline != null &&
      deadline.isAfter(now ?? DateTime.now());
}

Future<Object?> _startMedicalDocumentReplacement(
  BuildContext context, {
  required MedicalDocumentDetailCubit cubit,
  required MedicalDocumentEntity document,
  String? replacementAnimalId,
  VoidCallback? onReadyToNavigate,
}) async {
  final related = await cubit.loadRelatedDocuments(document.id);
  if (!context.mounted || related == null) return null;

  var anchor = document;
  for (final relatedDocument in related) {
    if (relatedDocument.id == document.id) {
      anchor = relatedDocument;
      break;
    }
  }
  if (!_hasActiveMedicalDocumentEditingWindow(anchor)) {
    ErrorDisplay.showError(context, _medicalDocumentEditingExpiredMessage);
    return null;
  }

  final originalFile = await cubit.loadOriginalFile(anchor);
  if (!context.mounted || originalFile == null) return null;

  onReadyToNavigate?.call();
  return Navigator.pushNamed<Object?>(
    context,
    AppRoutes.sharedFileUpload,
    arguments: {
      'manualUpload': true,
      medicalDocumentReplacementAnchorArgument: anchor,
      medicalDocumentRelatedDocumentsArgument: related,
      medicalDocumentReplacementFileArgument: originalFile,
      medicalDocumentReplacementFileDateArgument:
          anchor.updatedAt ??
          anchor.acceptedAt ??
          anchor.createdAt ??
          DateTime.now(),
      if (replacementAnimalId?.isNotEmpty == true)
        medicalDocumentReplacementAnimalIdArgument: replacementAnimalId,
    },
  );
}

bool _openReplacementDestination(
  BuildContext context, {
  required SharedFileUploadResult result,
  required MedicalDocumentCategory currentCategory,
}) {
  if (result.category == null || result.category == currentCategory) {
    return false;
  }
  final destination = resolveSharedFileUploadDestination(result);
  final sectionRouteName = destination?.sectionRouteName;
  if (sectionRouteName == null) return false;

  Navigator.of(context).pushReplacementNamed(
    sectionRouteName,
    arguments: destination!.sectionArguments,
  );
  return true;
}

enum _MedicalDocumentCardAction { download, continueEditing, delete }

class MedicalDocumentActionsMenu extends StatefulWidget {
  final String animalId;
  final MedicalDocumentEntity document;
  final MedicalDocumentCategory category;
  final Future<void> Function()? onDownload;
  final VoidCallback? onChanged;
  final Key? menuKey;

  const MedicalDocumentActionsMenu({
    super.key,
    required this.animalId,
    required this.document,
    required this.category,
    this.onDownload,
    this.onChanged,
    this.menuKey,
  });

  @override
  State<MedicalDocumentActionsMenu> createState() =>
      _MedicalDocumentActionsMenuState();
}

class _MedicalDocumentActionsMenuState
    extends State<MedicalDocumentActionsMenu> {
  static const _menuCloseDuration = Duration(milliseconds: 320);
  static const _editingMenuWidth = 215.0;
  static const _downloadMenuWidth = 203.0;

  late final MedicalDocumentDetailCubit _detailCubit;
  final _loadingOverlay = AppLoadingOverlay();
  Timer? _expiryTimer;
  bool _isBusy = false;

  bool get _hasActiveEditingWindow =>
      _hasActiveMedicalDocumentEditingWindow(widget.document);

  @override
  void initState() {
    super.initState();
    _detailCubit = di.sl<MedicalDocumentDetailCubit>();
    _scheduleExpiry();
  }

  @override
  void didUpdateWidget(covariant MedicalDocumentActionsMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleExpiry();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _loadingOverlay.hide();
    _detailCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEditingActions = _hasActiveEditingWindow;
    if (!hasEditingActions && widget.onDownload == null) {
      return const SizedBox.shrink();
    }

    final menuWidth = hasEditingActions
        ? _editingMenuWidth
        : _downloadMenuWidth;

    return AppPopupActionMenu<_MedicalDocumentCardAction>(
      menuKey:
          widget.menuKey ?? Key('medical-document-menu-${widget.document.id}'),
      actions: [
        if (widget.onDownload != null)
          AppPopupMenuAction(
            key: Key('medical-document-download-${widget.document.id}'),
            value: _MedicalDocumentCardAction.download,
            label: 'Descargar historia',
            iconAsset: AppIcons.receiveSquare,
            iconColor: AppColors.greyMedio,
          ),
        if (hasEditingActions) ...[
          AppPopupMenuAction(
            key: Key('medical-document-continue-${widget.document.id}'),
            value: _MedicalDocumentCardAction.continueEditing,
            label: 'Continuar editando',
            iconAsset: 'assets/icons/icon_edit 1.svg',
            iconColor: AppColors.greyMedio,
          ),
          AppPopupMenuAction(
            key: Key('medical-document-delete-${widget.document.id}'),
            value: _MedicalDocumentCardAction.delete,
            label: 'Eliminar archivo',
            iconAsset: 'assets/icons/icon_trash.svg',
            iconColor: AppColors.errorRojo,
            textColor: AppColors.errorRojo,
          ),
        ],
      ],
      enabled: !_isBusy,
      offset: Offset(-(menuWidth - 28), 42),
      menuWidth: menuWidth,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
      ),
      icon: const Icon(Icons.more_vert, color: AppColors.primaryFrances),
      onSelected: _onSelected,
    );
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final deadline = _medicalDocumentEditingDeadline(widget.document);
    if (!widget.document.canReplace || deadline == null) return;

    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _expiryTimer = Timer(remaining, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onSelected(_MedicalDocumentCardAction action) async {
    if (_isBusy) return;
    await Future<void>.delayed(_menuCloseDuration);
    if (!mounted) return;

    switch (action) {
      case _MedicalDocumentCardAction.download:
        await _download();
        break;
      case _MedicalDocumentCardAction.continueEditing:
        if (_hasActiveEditingWindow) await _continueEditing();
        break;
      case _MedicalDocumentCardAction.delete:
        if (_hasActiveEditingWindow) _confirmDelete();
        break;
    }
  }

  Future<void> _download() async {
    final onDownload = widget.onDownload;
    if (onDownload == null) return;

    setState(() => _isBusy = true);
    _loadingOverlay.show(context);
    try {
      await onDownload();
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    } finally {
      _loadingOverlay.hide();
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _continueEditing() async {
    final documentsCubit = context.read<AnimalMedicalDocumentsCubit>();
    setState(() => _isBusy = true);
    _loadingOverlay.show(context);
    Object? result;
    try {
      result = await _startMedicalDocumentReplacement(
        context,
        cubit: _detailCubit,
        document: widget.document,
        replacementAnimalId: widget.animalId,
        onReadyToNavigate: _loadingOverlay.hide,
      );
    } finally {
      _loadingOverlay.hide();
    }
    if (!mounted) return;

    if (result is SharedFileUploadResult &&
        _openReplacementDestination(
          context,
          result: result,
          currentCategory: widget.category,
        )) {
      return;
    }
    if (result == true || result is SharedFileUploadResult) {
      await documentsCubit.load(widget.animalId, category: widget.category);
      if (mounted) widget.onChanged?.call();
    } else if (result == false) {
      final overlay = Navigator.of(context).overlay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay != null) {
          ErrorDisplay.showErrorOnOverlay(
            overlay,
            _medicalDocumentUploadFailureMessage,
          );
        }
      });
    } else {
      _showCubitError();
    }
    if (mounted) setState(() => _isBusy = false);
  }

  void _confirmDelete() {
    if (!_hasActiveEditingWindow) return;
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: '¿Desea eliminar el archivo?',
        description:
            'Al eliminar este archivo, no podrás recuperarlo ni volver a verlo.',
        confirmLabel: 'Sí',
        cancelLabel: 'No',
        onConfirm: _delete,
      ),
    );
  }

  Future<void> _delete() async {
    if (!_hasActiveEditingWindow) {
      ErrorDisplay.showError(context, _medicalDocumentEditingExpiredMessage);
      return;
    }

    final documentsCubit = context.read<AnimalMedicalDocumentsCubit>();
    setState(() => _isBusy = true);
    _loadingOverlay.show(context);
    late final bool deleted;
    try {
      deleted = await _detailCubit.deleteDocument(
        animalId: widget.animalId,
        documentId: widget.document.id,
        documentVersion: widget.document.version,
      );
    } finally {
      _loadingOverlay.hide();
    }
    if (!mounted) return;

    if (deleted) {
      await documentsCubit.load(widget.animalId, category: widget.category);
      if (mounted) widget.onChanged?.call();
    } else {
      _showCubitError();
    }
    if (mounted) setState(() => _isBusy = false);
  }

  void _showCubitError() {
    final message = _detailCubit.state.message;
    if (message?.isNotEmpty == true) ErrorDisplay.showError(context, message!);
  }
}

Future<bool?> showMedicalDocumentDetail(
  BuildContext context, {
  String? animalId,
  required MedicalDocumentEntity document,
  required MedicalDocumentCategory category,
  SharedFileAppProfile? appProfile,
}) async {
  late final SharedFileAnalysisEntity analysis;
  try {
    analysis = await di.sl<MedicalDocumentAnalysisPresenter>().forAccepted(
      document,
      appPatient: appProfile?.patient,
      appTutor: appProfile?.tutor,
    );
  } catch (error) {
    if (context.mounted) ErrorDisplay.showError(context, error.toString());
    return null;
  }
  if (!context.mounted) return null;
  final result = await Navigator.push<Object?>(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => di.sl<MedicalDocumentDetailCubit>(),
        child: _AcceptedMedicalDocumentDetailScreen(
          analysis: analysis,
          animalId:
              animalId ??
              (document.animalIds.isEmpty ? null : document.animalIds.first),
          document: document,
          category: category,
        ),
      ),
    ),
  );
  final changed = result == true || result is SharedFileUploadResult;
  final affectedAnimalId =
      animalId ??
      (document.animalIds.isEmpty ? null : document.animalIds.first);
  if (result is SharedFileUploadResult &&
      context.mounted &&
      _openReplacementDestination(
        context,
        result: result,
        currentCategory: category,
      )) {
    return true;
  }
  if (changed == true && context.mounted && affectedAnimalId != null) {
    await context.read<AnimalMedicalDocumentsCubit>().load(
      affectedAnimalId,
      category: category,
    );
  }
  return changed;
}

class _AcceptedMedicalDocumentDetailScreen extends StatefulWidget {
  final SharedFileAnalysisEntity analysis;
  final String? animalId;
  final MedicalDocumentEntity document;
  final MedicalDocumentCategory category;

  const _AcceptedMedicalDocumentDetailScreen({
    required this.analysis,
    required this.animalId,
    required this.document,
    required this.category,
  });

  @override
  State<_AcceptedMedicalDocumentDetailScreen> createState() =>
      _AcceptedMedicalDocumentDetailScreenState();
}

class _AcceptedMedicalDocumentDetailScreenState
    extends State<_AcceptedMedicalDocumentDetailScreen> {
  final _closeIconKey = GlobalKey();
  final _actionIconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicalDocumentDetailCubit, MedicalDocumentDetailState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        if (state.message?.isNotEmpty == true) {
          ErrorDisplay.showError(context, state.message!);
        }
      },
      builder: (context, state) => SharedFileSendScreen(
        analysis: widget.analysis,
        closeIconKey: _closeIconKey,
        actionIconKey: _actionIconKey,
        replacementDeadline: _medicalDocumentEditingDeadline(widget.document),
        canReplace: widget.document.canReplace,
        isActionLoading: state.isBusy,
        onContinueEditing: _continueEditing,
        onDelete: _confirmDelete,
        onViewOriginalText: (text) => _showMedicalDocumentOriginal(
          context,
          document: widget.document,
          closeIconKey: _closeIconKey,
          downloadIconKey: _actionIconKey,
          searchText: text,
        ),
        resolveOriginalUri: () =>
            di.sl<GetMedicalDocumentDownloadUriUseCase>()(widget.document.id),
        actionLabel: medicalDocumentSendActionLabel(widget.category),
      ),
    );
  }

  Future<void> _continueEditing() async {
    final replaced = await _startMedicalDocumentReplacement(
      context,
      cubit: context.read<MedicalDocumentDetailCubit>(),
      document: widget.document,
      replacementAnimalId: widget.animalId,
    );
    if (mounted && (replaced == true || replaced is SharedFileUploadResult)) {
      Navigator.pop(context, replaced);
    } else if (mounted && replaced == false) {
      final navigator = Navigator.of(context);
      final overlay = navigator.overlay;
      navigator.pop(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay != null) {
          ErrorDisplay.showErrorOnOverlay(
            overlay,
            _medicalDocumentUploadFailureMessage,
          );
        }
      });
    }
  }

  void _confirmDelete() {
    if (!_hasActiveMedicalDocumentEditingWindow(widget.document)) return;
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: '¿Desea eliminar el archivo?',
        description:
            'Al eliminar este archivo, no podrás recuperarlo ni volver a verlo.',
        confirmLabel: 'Sí',
        cancelLabel: 'No',
        onConfirm: _delete,
      ),
    );
  }

  Future<void> _delete() async {
    if (!_hasActiveMedicalDocumentEditingWindow(widget.document)) {
      ErrorDisplay.showError(context, _medicalDocumentEditingExpiredMessage);
      return;
    }
    final animalId = widget.animalId;
    if (animalId == null || animalId.isEmpty) {
      ErrorDisplay.showError(
        context,
        'No fue posible identificar el animal asociado al archivo.',
      );
      return;
    }
    final deleted = await context
        .read<MedicalDocumentDetailCubit>()
        .deleteDocument(
          animalId: animalId,
          documentId: widget.document.id,
          documentVersion: widget.document.version,
        );
    if (mounted && deleted) Navigator.pop(context, true);
  }
}

Future<void> _showMedicalDocumentOriginal(
  BuildContext context, {
  required MedicalDocumentEntity document,
  GlobalKey? closeIconKey,
  GlobalKey? downloadIconKey,
  String? searchText,
}) async {
  final preview = MedicalDocumentOriginalPreview(
    getDownloadUriUseCase: di.sl<GetMedicalDocumentDownloadUriUseCase>(),
    saveOriginalUseCase: di.sl<SaveMedicalDocumentOriginalUseCase>(),
  );
  try {
    await preview.show(
      context,
      acceptedDocumentId: document.id,
      fileName: document.originalFileName,
      mimeType: document.mimeType,
      closeIconKey: closeIconKey,
      downloadIconKey: downloadIconKey,
      searchText: searchText,
    );
  } catch (error) {
    if (context.mounted) ErrorDisplay.showError(context, error.toString());
  }
}

class _DocumentCardValue extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  final double spacing;

  const _DocumentCardValue({
    required this.label,
    required this.value,
    required this.maxLines,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
            ),
          ),
          if (spacing > 0) SizedBox(width: spacing),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              softWrap: maxLines == 1 ? false : null,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }
}

String _documentNumber(MedicalDocumentEntity document) {
  if (document.finalCategory == MedicalDocumentCategory.vaccinationCard) {
    return '';
  }
  final value = document.documentCode.trim();
  if (value.isEmpty) return '';
  return value.startsWith('N°') ? value : 'N° $value';
}

String _searchableDocumentText(MedicalDocumentEntity document) {
  final extraction = document.validatedExtraction;
  return [
    document.originalFileName,
    document.finalCategory?.label,
    extraction?.documentDate,
    ...?extraction?.diagnoses.expand(_itemSearchValues),
    ...?extraction?.medications.expand(_itemSearchValues),
    ...?extraction?.vaccinations.expand(_itemSearchValues),
    ...?extraction?.medicalOrders.expand(_itemSearchValues),
    ...?extraction?.diagnosticResults.expand(_itemSearchValues),
    ...?extraction?.diagnosticImages.expand(_itemSearchValues),
    ...?extraction?.laboratoryResults.expand(_itemSearchValues),
    ...?extraction?.clinicalHistory?.values,
    ...?extraction?.referral?.values,
    ...?extraction?.laboratoryReport?.values,
    ...?extraction?.additionalFields.values,
  ].whereType<Object>().map(_valueText).join(' ').toLowerCase();
}

Iterable<Object?> _itemSearchValues(MedicalDocumentItemEntity item) => [
  item.id,
  ...item.fields.values,
];

String _valueText(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value.map(_valueText).where((item) => item.isNotEmpty).join(' ');
  }
  if (value is Map) {
    return value.entries
        .where(
          (entry) =>
              !isMedicalDocumentTechnicalKey(entry.key.toString(), const {}),
        )
        .map((entry) => _valueText(entry.value))
        .where((item) => item.isNotEmpty)
        .join(' ');
  }
  return value.toString().trim();
}
