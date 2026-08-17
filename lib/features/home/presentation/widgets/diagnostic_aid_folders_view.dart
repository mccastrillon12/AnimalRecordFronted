import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiagnosticAidFoldersView extends StatelessWidget {
  final String animalId;
  final String query;
  final bool ascending;
  final GlobalKey? closeIconKey;

  const DiagnosticAidFoldersView({
    super.key,
    required this.animalId,
    required this.query,
    required this.ascending,
    this.closeIconKey,
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
                      .load(animalId, category: MedicalDocumentCategory.other),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != MedicalDocumentCategory.other) {
          return const SizedBox.shrink();
        }

        final sorted = [...state.documents]
          ..sort((left, right) {
            final comparison = _documentDate(
              left,
            ).compareTo(_documentDate(right));
            return ascending ? comparison : -comparison;
          });
        final normalizedQuery = query.trim().toLowerCase();
        final folders = sorted.indexed
            .map(
              (entry) => _DiagnosticAidFolder(
                position: entry.$1 + 1,
                document: entry.$2,
              ),
            )
            .where(
              (folder) =>
                  normalizedQuery.isEmpty ||
                  folder.position.toString().contains(normalizedQuery) ||
                  folder.document.originalFileName.toLowerCase().contains(
                    normalizedQuery,
                  ),
            )
            .toList(growable: false);

        if (state.documents.isEmpty) {
          return const _DiagnosticAidsEmptyState();
        }
        if (folders.isEmpty) return const _DiagnosticAidsNoResults();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              spacing: AppSpacing.l,
              runSpacing: AppSpacing.l,
              children: folders
                  .map(
                    (folder) => _DiagnosticAidFolderTile(
                      folder: folder,
                      onTap: () => _showOriginal(
                        context,
                        folder.document,
                        closeIconKey: closeIconKey,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }

  static DateTime _documentDate(MedicalDocumentEntity document) =>
      document.updatedAt ??
      document.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _showOriginal(
    BuildContext context,
    MedicalDocumentEntity document, {
    GlobalKey? closeIconKey,
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
      );
    } catch (error) {
      if (context.mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class _DiagnosticAidFolder {
  final int position;
  final MedicalDocumentEntity document;

  const _DiagnosticAidFolder({required this.position, required this.document});
}

class _DiagnosticAidFolderTile extends StatelessWidget {
  final _DiagnosticAidFolder folder;
  final VoidCallback onTap;

  const _DiagnosticAidFolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ayuda diagnóstica ${folder.position}',
      child: InkWell(
        key: Key('diagnostic-aid-folder-${folder.document.id}'),
        onTap: onTap,
        borderRadius: AppBorders.small(),
        child: SizedBox(
          width: 75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                key: Key('diagnostic-aid-file-preview-${folder.document.id}'),
                width: 75,
                height: 64,
                child: _DiagnosticAidFilePreview(document: folder.document),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '${folder.position}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body6.copyWith(
                  color: AppColors.greyTextos,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticAidFilePreview extends StatefulWidget {
  final MedicalDocumentEntity document;

  const _DiagnosticAidFilePreview({required this.document});

  @override
  State<_DiagnosticAidFilePreview> createState() =>
      _DiagnosticAidFilePreviewState();
}

class _DiagnosticAidFilePreviewState extends State<_DiagnosticAidFilePreview> {
  late Future<Uri>? _imageUri;

  @override
  void initState() {
    super.initState();
    _imageUri = _isImage(widget.document)
        ? di.sl<GetMedicalDocumentDownloadUriUseCase>()(widget.document.id)
        : null;
  }

  @override
  void didUpdateWidget(covariant _DiagnosticAidFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.document.mimeType != widget.document.mimeType) {
      _imageUri = _isImage(widget.document)
          ? di.sl<GetMedicalDocumentDownloadUriUseCase>()(widget.document.id)
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPdf(widget.document)) return _pdfThumbnail();
    if (!_isImage(widget.document)) return _fallbackThumbnail();

    return FutureBuilder<Uri>(
      future: _imageUri,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _fallbackThumbnail();
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: snapshot.data.toString(),
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            errorWidget: (_, _, _) => _fallbackThumbnail(),
          ),
        );
      },
    );
  }

  Widget _pdfThumbnail() => ColoredBox(
    color: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Image.asset('assets/icons/pdf.png', fit: BoxFit.contain),
    ),
  );

  Widget _fallbackThumbnail() => const ColoredBox(
    color: Color(0xFFD9D9D9),
    child: Center(
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: AppSpacing.iconSizeSmall,
        color: AppColors.greyBordes,
      ),
    ),
  );

  bool _isPdf(MedicalDocumentEntity document) =>
      document.mimeType.toLowerCase() == 'application/pdf' ||
      document.originalFileName.toLowerCase().endsWith('.pdf');

  bool _isImage(MedicalDocumentEntity document) {
    if (document.mimeType.toLowerCase().startsWith('image/')) return true;
    const extensions = ['.jpeg', '.jpg', '.png', '.tif', '.tiff', '.webp'];
    final name = document.originalFileName.toLowerCase();
    return extensions.any(name.endsWith);
  }
}

class _DiagnosticAidsEmptyState extends StatelessWidget {
  const _DiagnosticAidsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El registro de ayudas diagnósticas está vacío',
              style: AppTypography.body3.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Aquí se podrán visualizar las ayudas diagnósticas que se creen.',
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticAidsNoResults extends StatelessWidget {
  const _DiagnosticAidsNoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No se encontraron ayudas diagnósticas.',
        style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
        textAlign: TextAlign.center,
      ),
    );
  }
}
