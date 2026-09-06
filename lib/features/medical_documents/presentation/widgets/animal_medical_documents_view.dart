import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/services/medical_document_analysis_presenter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_ai_feedback_banner.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef MedicalDocumentThumbnailUriLoader =
    Future<Uri> Function(String documentId);

const _diagnosticThumbnailCacheLifetime = Duration(minutes: 5);
final _diagnosticThumbnailUriCache = _DiagnosticThumbnailUriCache();

Future<Uri> _loadMedicalDocumentThumbnailUri(String documentId) =>
    di.sl<GetMedicalDocumentDownloadUriUseCase>()(documentId);

class AnimalMedicalDocumentsView extends StatelessWidget {
  final String animalId;
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
  final MedicalDocumentThumbnailUriLoader? diagnosticThumbnailUriLoader;

  const AnimalMedicalDocumentsView({
    super.key,
    required this.animalId,
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
    this.diagnosticThumbnailUriLoader,
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
        if (documents.isEmpty && !shouldShowAiFeedback) {
          return _EmptyState(
            title: emptyTitle,
            description: emptyDescription,
            bottomOffset: emptyBottomOffset,
          );
        }
        if (category == MedicalDocumentCategory.diagnosticImage &&
            !shouldShowAiFeedback) {
          return _DiagnosticImagesGrid(
            documents: documents,
            loadThumbnailUri:
                diagnosticThumbnailUriLoader ??
                _loadMedicalDocumentThumbnailUri,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          itemCount: documents.length + (shouldShowAiFeedback ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) => shouldShowAiFeedback && index == 0
              ? MedicalDocumentAiFeedbackBanner(
                  key: ValueKey(aiFeedbackRequestId),
                  onDismissed: onAiFeedbackDismissed,
                  onSubmit: onAiFeedback ?? _submitAiFeedback,
                  initialHasResponded: initialAiFeedbackResponded,
                  onSubmitted: onAiFeedbackSubmitted,
                )
              : MedicalDocumentSummaryCard(
                  document: documents[index - (shouldShowAiFeedback ? 1 : 0)],
                  category:
                      documents[index - (shouldShowAiFeedback ? 1 : 0)]
                          .finalCategory ??
                      category,
                ),
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

class MedicalDocumentSummaryCard extends StatelessWidget {
  final MedicalDocumentEntity document;
  final MedicalDocumentCategory category;

  const MedicalDocumentSummaryCard({
    super.key,
    required this.document,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final extraction = document.validatedExtraction;
    final date = displayMedicalDocumentDate(extraction?.documentDate);
    final description = _documentDescription(document);
    final number = _documentNumber(document);
    final title = [
      'Adjunto: ${document.finalCategory?.label ?? 'Archivo médico'}',
      if (number.isNotEmpty) number,
    ].join(' ');
    return MedicalDocumentCard(
      key: Key('medical-document-card-${document.id}'),
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
        title,
        style: AppTypography.body3.copyWith(color: AppColors.greyTextos),
      ),
      body:
          date.isNotEmpty ||
              document.originalFileName.trim().isNotEmpty ||
              description.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.iconSizeSmall + AppSpacing.m,
              ),
              child: Column(
                children: [
                  if (date.isNotEmpty)
                    _DocumentCardValue(label: 'Fecha:', value: date),
                  if (document.originalFileName.trim().isNotEmpty)
                    _DocumentCardValue(
                      label: 'Archivo:',
                      value: document.originalFileName,
                    ),
                  if (description.isNotEmpty)
                    _DocumentCardValue(
                      label: 'Descripción:',
                      value: description,
                    ),
                ],
              ),
            )
          : null,
      footer: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          key: Key('medical-document-detail-${document.id}'),
          onTap: extraction == null
              ? null
              : () => _showMedicalDocumentDetail(
                  context,
                  document: document,
                  category: category,
                ),
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

class _DiagnosticImagesGrid extends StatelessWidget {
  final List<MedicalDocumentEntity> documents;
  final MedicalDocumentThumbnailUriLoader loadThumbnailUri;

  const _DiagnosticImagesGrid({
    required this.documents,
    required this.loadThumbnailUri,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.l,
          children: [
            for (final document in documents)
              _DiagnosticImageTile(
                key: ValueKey(document.id),
                document: document,
                loadThumbnailUri: loadThumbnailUri,
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticImageTile extends StatefulWidget {
  final MedicalDocumentEntity document;
  final MedicalDocumentThumbnailUriLoader loadThumbnailUri;

  const _DiagnosticImageTile({
    super.key,
    required this.document,
    required this.loadThumbnailUri,
  });

  @override
  State<_DiagnosticImageTile> createState() => _DiagnosticImageTileState();
}

class _DiagnosticImageTileState extends State<_DiagnosticImageTile> {
  late Future<Uri> _thumbnailUri;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _DiagnosticImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        !identical(oldWidget.loadThumbnailUri, widget.loadThumbnailUri)) {
      _loadThumbnail();
    }
  }

  Uri? _initialThumbnailUri;

  void _loadThumbnail() {
    _initialThumbnailUri = _diagnosticThumbnailUriCache.peek(
      widget.document.id,
      widget.loadThumbnailUri,
    );
    _thumbnailUri = _diagnosticThumbnailUriCache.load(
      widget.document.id,
      widget.loadThumbnailUri,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        key: Key('diagnostic-image-${widget.document.id}'),
        onTap: widget.document.validatedExtraction == null
            ? null
            : () => _showMedicalDocumentDetail(
                context,
                document: widget.document,
                category: MedicalDocumentCategory.diagnosticImage,
              ),
        borderRadius: AppBorders.small(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: Key('diagnostic-image-thumbnail-${widget.document.id}'),
              width: 140,
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.bgBlancoAntiFlash,
                border: Border.all(color: AppColors.greyDelineante),
              ),
              child: FutureBuilder<Uri>(
                future: _thumbnailUri,
                initialData: _initialThumbnailUri,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.network(
                      snapshot.data.toString(),
                      width: 140,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ThumbnailFallback(),
                    );
                  }
                  if (snapshot.hasError) return const _ThumbnailFallback();
                  return const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.document.originalFileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticThumbnailUriCache {
  final Map<_DiagnosticThumbnailUriCacheKey, _DiagnosticThumbnailUriCacheEntry>
  _entries = {};

  Uri? peek(String documentId, MedicalDocumentThumbnailUriLoader loader) {
    final key = _DiagnosticThumbnailUriCacheKey(documentId, loader);
    final entry = _validEntry(key);
    return entry?.uri;
  }

  Future<Uri> load(
    String documentId,
    MedicalDocumentThumbnailUriLoader loader,
  ) async {
    final key = _DiagnosticThumbnailUriCacheKey(documentId, loader);
    final cached = _validEntry(key);
    if (cached != null) return cached.future;

    final entry = _DiagnosticThumbnailUriCacheEntry(DateTime.now());
    final request = loader(documentId);
    entry.future = request;
    _entries[key] = entry;

    try {
      final uri = await request;
      if (identical(_entries[key], entry)) entry.uri = uri;
      return uri;
    } catch (_) {
      if (identical(_entries[key], entry)) _entries.remove(key);
      rethrow;
    }
  }

  _DiagnosticThumbnailUriCacheEntry? _validEntry(
    _DiagnosticThumbnailUriCacheKey key,
  ) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) <
        _diagnosticThumbnailCacheLifetime) {
      return entry;
    }
    _entries.remove(key);
    return null;
  }
}

class _DiagnosticThumbnailUriCacheEntry {
  final DateTime cachedAt;
  late final Future<Uri> future;
  Uri? uri;

  _DiagnosticThumbnailUriCacheEntry(this.cachedAt);
}

class _DiagnosticThumbnailUriCacheKey {
  final String documentId;
  final MedicalDocumentThumbnailUriLoader loader;

  const _DiagnosticThumbnailUriCacheKey(this.documentId, this.loader);

  @override
  bool operator ==(Object other) =>
      other is _DiagnosticThumbnailUriCacheKey &&
      documentId == other.documentId &&
      identical(loader, other.loader);

  @override
  int get hashCode => Object.hash(documentId, identityHashCode(loader));
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, color: AppColors.greyIconos, size: 28),
    );
  }
}

Future<void> _showMedicalDocumentDetail(
  BuildContext context, {
  required MedicalDocumentEntity document,
  required MedicalDocumentCategory category,
}) async {
  final closeIconKey = GlobalKey();
  final actionIconKey = GlobalKey();
  late final SharedFileAnalysisEntity analysis;
  try {
    analysis = await di.sl<MedicalDocumentAnalysisPresenter>().forAccepted(
      document,
    );
  } catch (error) {
    if (context.mounted) ErrorDisplay.showError(context, error.toString());
    return;
  }
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (detailContext) => SharedFileSendScreen(
        analysis: analysis,
        closeIconKey: closeIconKey,
        actionIconKey: actionIconKey,
        onViewOriginal: () => _showMedicalDocumentOriginal(
          detailContext,
          document: document,
          closeIconKey: closeIconKey,
          downloadIconKey: actionIconKey,
        ),
        resolveOriginalUri: () =>
            di.sl<GetMedicalDocumentDownloadUriUseCase>()(document.id),
        actionLabel: medicalDocumentSendActionLabel(category),
      ),
    ),
  );
}

Future<void> _showMedicalDocumentOriginal(
  BuildContext context, {
  required MedicalDocumentEntity document,
  required GlobalKey closeIconKey,
  GlobalKey? downloadIconKey,
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
    );
  } catch (error) {
    if (context.mounted) ErrorDisplay.showError(context, error.toString());
  }
}

class _DocumentCardValue extends StatelessWidget {
  final String label;
  final String value;

  const _DocumentCardValue({required this.label, required this.value});

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
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeedbackBanner extends StatefulWidget {
  final VoidCallback? onDismissed;
  final Future<void> Function(MedicalDocumentAiFeedback feedback) onSubmit;
  final bool initialHasResponded;
  final Future<void> Function()? onSubmitted;

  const _AiFeedbackBanner({
    super.key,
    this.onDismissed,
    required this.onSubmit,
    this.initialHasResponded = false,
    this.onSubmitted,
  });

  @override
  State<_AiFeedbackBanner> createState() => _AiFeedbackBannerState();
}

class _AiFeedbackBannerState extends State<_AiFeedbackBanner> {
  late bool _hasResponded;
  bool _isDismissed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hasResponded = widget.initialHasResponded;
  }

  @override
  void didUpdateWidget(covariant _AiFeedbackBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasResponded && widget.initialHasResponded) {
      _hasResponded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    if (_hasResponded) {
      return Container(
        key: const Key('medical-document-ai-feedback-thanks'),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: AppColors.aiAnalysisGradient,
          borderRadius: AppBorders.large(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Gracias por tu respuesta, la tendremos en cuenta para seguir '
                'entrenando la IA.',
                style: AppTypography.body6.copyWith(
                  color: AppColors.greyNegro,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            IconButton(
              key: const Key('medical-document-ai-feedback-close'),
              onPressed: _dismiss,
              icon: const Icon(
                Icons.close,
                color: AppColors.greyIconos,
                size: 24,
              ),
              tooltip: 'Cerrar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.xl,
                minHeight: AppSpacing.xl,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.small(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¿La ayuda de la IA te fue útil para leer tu archivo?',
              style: AppTypography.body6.copyWith(
                color: const Color.fromARGB(255, 0, 0, 0),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          _AiFeedbackButton(
            key: const Key('medical-document-ai-not-useful'),
            icon: Icons.thumb_down_alt,
            onTap: _isSubmitting
                ? null
                : () => _submitFeedback(MedicalDocumentAiFeedback.dislike),
          ),
          const SizedBox(width: AppSpacing.m),
          _AiFeedbackButton(
            key: const Key('medical-document-ai-useful'),
            icon: Icons.thumb_up_alt,
            onTap: _isSubmitting
                ? null
                : () => _submitFeedback(MedicalDocumentAiFeedback.like),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback(MedicalDocumentAiFeedback feedback) async {
    if (_isSubmitting || _hasResponded) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(feedback);
      await widget.onSubmitted?.call();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasResponded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ErrorDisplay.showError(context, error.toString());
    }
  }

  void _dismiss() {
    setState(() => _isDismissed = true);
    widget.onDismissed?.call();
  }
}

class _AiFeedbackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AiFeedbackButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: Ink(
          width: 62,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.primaryFrances),
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Center(
            child: Icon(icon, size: 23, color: AppColors.primaryFrances),
          ),
        ),
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

String _documentDescription(MedicalDocumentEntity document) {
  final extraction = document.validatedExtraction;
  final additionalFields =
      extraction?.additionalFields ?? const <String, dynamic>{};
  for (final entry in additionalFields.entries) {
    if (const {
      'description',
      'descripcion',
    }.contains(_normalizedFieldKey(entry.key))) {
      final value = _valueText(entry.value).trim();
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String _normalizedFieldKey(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _searchableDocumentText(MedicalDocumentEntity document) {
  final extraction = document.validatedExtraction;
  return [
    document.originalFileName,
    document.finalCategory?.label,
    extraction?.documentDate,
    ...?extraction?.patientHints,
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
        .where((entry) => entry.key != 'source' && entry.key != 'confidence')
        .map((entry) => _valueText(entry.value))
        .where((item) => item.isNotEmpty)
        .join(' ');
  }
  return value.toString().trim();
}
