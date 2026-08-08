import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdfrx/pdfrx.dart';

typedef _MedicalDocumentUriLoader = Future<Uri> Function();

class MedicalDocumentOriginalPreview {
  final GetMedicalDocumentDownloadUriUseCase getDownloadUriUseCase;
  final SaveMedicalDocumentOriginalUseCase saveOriginalUseCase;

  const MedicalDocumentOriginalPreview({
    required this.getDownloadUriUseCase,
    required this.saveOriginalUseCase,
  });

  Future<void> show(
    BuildContext context, {
    SharedFileEntity? localFile,
    String? acceptedDocumentId,
    String? fileName,
    required String mimeType,
  }) async {
    final remoteUriLoader = localFile == null && acceptedDocumentId != null
        ? () => getDownloadUriUseCase(acceptedDocumentId)
        : null;
    final isPdf = mimeType.toLowerCase() == 'application/pdf';

    if (isPdf) {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.overlayBlack,
        builder: (_) => _PdfPreviewDialog(
          localFile: localFile,
          remoteUriLoader: remoteUriLoader,
          fileName: fileName ?? localFile?.name ?? 'documento_medico.pdf',
          saveOriginalUseCase: saveOriginalUseCase,
        ),
      );
      return;
    }

    final remoteUri = remoteUriLoader == null ? null : await remoteUriLoader();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => ImagePreviewDialog(
        imageUrl: remoteUri?.toString() ?? localFile?.path ?? '',
        imageBytes: localFile?.bytes,
      ),
    );
  }
}

class _PdfPreviewDialog extends StatefulWidget {
  final SharedFileEntity? localFile;
  final _MedicalDocumentUriLoader? remoteUriLoader;
  final String fileName;
  final SaveMedicalDocumentOriginalUseCase saveOriginalUseCase;

  const _PdfPreviewDialog({
    required this.localFile,
    required this.remoteUriLoader,
    required this.fileName,
    required this.saveOriginalUseCase,
  });

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  static const _viewerParams = PdfViewerParams(
    margin: AppSpacing.s,
    backgroundColor: Colors.transparent,
    pageDropShadow: null,
    calculateInitialZoom: _fitPageWidth,
  );

  late Future<Uri?> _remoteUriFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _remoteUriFuture = _loadRemoteUri();
  }

  Future<Uri?> _loadRemoteUri() async {
    if (widget.localFile != null) return null;
    return widget.remoteUriLoader?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                right: AppSpacing.s,
              ),
              child: SizedBox(
                height: AppSpacing.iconSizeSmall,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _isDownloading ? null : _download,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.iconSizeSmall,
                        height: AppSpacing.iconSizeSmall,
                      ),
                      iconSize: AppSpacing.iconSizeSmall,
                      icon: _isDownloading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : SvgPicture.asset(
                              AppIcons.receiveSquare,
                              width: AppSpacing.iconSizeSmall,
                              height: AppSpacing.iconSizeSmall,
                              colorFilter: const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                      tooltip: 'Descargar PDF',
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.iconSizeSmall,
                        height: AppSpacing.iconSizeSmall,
                      ),
                      iconSize: AppSpacing.iconSizeSmall,
                      icon: const Icon(Icons.close, color: AppColors.white),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xxs,
                  right: AppSpacing.xxs,
                  bottom: AppSpacing.xxs,
                ),
                child: _buildDocument(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocument() {
    final localFile = widget.localFile;
    if (localFile != null) return _buildViewer(localFile: localFile);

    return FutureBuilder<Uri?>(
      future: _remoteUriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.white),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _PdfLoadError(onRetry: _retryLoad);
        }
        return _buildViewer(remoteUri: snapshot.data);
      },
    );
  }

  Widget _buildViewer({SharedFileEntity? localFile, Uri? remoteUri}) {
    if (localFile?.bytes case final bytes? when bytes.isNotEmpty) {
      return PdfViewer.data(
        bytes,
        sourceName: localFile!.name,
        params: _viewerParams,
      );
    }
    if (localFile != null && localFile.path.isNotEmpty) {
      return PdfViewer.file(localFile.path, params: _viewerParams);
    }
    if (remoteUri != null) {
      return PdfViewer.uri(remoteUri, params: _viewerParams);
    }
    return _PdfLoadError(onRetry: _retryLoad);
  }

  void _retryLoad() {
    setState(() => _remoteUriFuture = _loadRemoteUri());
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final localFile = widget.localFile;
      final remoteUri = localFile == null
          ? await widget.remoteUriLoader?.call()
          : null;
      final saved = await widget.saveOriginalUseCase(
        MedicalDocumentFileSaveRequest(
          fileName: widget.fileName,
          bytes: localFile?.bytes,
          localPath: localFile?.path,
          remoteUri: remoteUri,
        ),
      );
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF guardado correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ErrorDisplay.showError(
          context,
          'No fue posible descargar el PDF. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}

class _PdfLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PdfLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No fue posible abrir el documento.',
            style: TextStyle(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Reintentar',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

double _fitPageWidth(
  PdfDocument _,
  PdfViewerController _,
  double _,
  double coverZoom,
) {
  return coverZoom;
}
