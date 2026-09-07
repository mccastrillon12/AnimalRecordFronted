import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    GlobalKey? closeIconKey,
    GlobalKey? downloadIconKey,
    required String mimeType,
  }) async {
    final closeIconRect = _globalRect(closeIconKey);
    final downloadIconRect = _globalRect(downloadIconKey);
    final remoteUriLoader = localFile == null && acceptedDocumentId != null
        ? () => getDownloadUriUseCase(acceptedDocumentId)
        : null;
    final isPdf = mimeType.toLowerCase() == 'application/pdf';

    if (isPdf) {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.overlayBlack,
        useSafeArea: false,
        builder: (_) => _PdfPreviewDialog(
          localFile: localFile,
          remoteUriLoader: remoteUriLoader,
          fileName: fileName ?? localFile?.name ?? 'documento_medico.pdf',
          closeIconRect: closeIconRect,
          downloadIconRect: downloadIconRect,
          saveOriginalUseCase: saveOriginalUseCase,
        ),
      );
      return;
    }

    final remoteUri = remoteUriLoader == null ? null : await remoteUriLoader();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.overlayBlack,
      useSafeArea: false,
      builder: (_) => ImagePreviewDialog(
        imageUrl: remoteUri?.toString() ?? localFile?.path ?? '',
        imageBytes: localFile?.bytes,
        closeIconRect: closeIconRect,
        downloadIconRect: downloadIconRect,
        onDownload: () => _downloadImage(
          context,
          localFile: localFile,
          remoteUriLoader: remoteUriLoader,
          fileName: fileName ?? localFile?.name ?? 'documento_medico',
          mimeType: mimeType,
        ),
      ),
    );
  }

  Future<void> _downloadImage(
    BuildContext context, {
    required SharedFileEntity? localFile,
    required _MedicalDocumentUriLoader? remoteUriLoader,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final remoteUri = localFile == null
          ? await remoteUriLoader?.call()
          : null;
      final saved = await saveOriginalUseCase(
        MedicalDocumentFileSaveRequest(
          fileName: fileName,
          mimeType: mimeType,
          bytes: localFile?.bytes,
          localPath: localFile?.path,
          remoteUri: remoteUri,
        ),
      );
      if (saved && context.mounted) {
        ErrorDisplay.showSuccess(context, 'Se descargo correctamente');
      }
    } catch (error) {
      if (context.mounted) {
        ErrorDisplay.showError(
          context,
          'No fue posible descargar la imagen. Inténtalo nuevamente.',
        );
      }
    }
  }
}

class _PdfPreviewDialog extends StatefulWidget {
  final SharedFileEntity? localFile;
  final _MedicalDocumentUriLoader? remoteUriLoader;
  final String fileName;
  final Rect? closeIconRect;
  final Rect? downloadIconRect;
  final SaveMedicalDocumentOriginalUseCase saveOriginalUseCase;

  const _PdfPreviewDialog({
    required this.localFile,
    required this.remoteUriLoader,
    required this.fileName,
    required this.closeIconRect,
    required this.downloadIconRect,
    required this.saveOriginalUseCase,
  });

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  static const _controlsDocumentGap = 20.0;
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
    final navigationBarColor = Color.alphaBlend(
      AppColors.overlayBlack,
      AppColors.white,
    );
    final safeAreaTop = MediaQuery.paddingOf(context).top;
    final closeButtonRect = _localPreviewRect(
      widget.closeIconRect,
      safeAreaTop: safeAreaTop,
      fallback: Rect.fromLTWH(
        MediaQuery.sizeOf(context).width - AppSpacing.l - previewControlSize,
        AppSpacing.l,
        previewControlSize,
        previewControlSize,
      ),
    );
    final downloadButtonRect = previewDownloadControlRect(
      _localPreviewRect(
        widget.downloadIconRect,
        safeAreaTop: safeAreaTop,
        fallback: Rect.fromLTWH(
          AppSpacing.l,
          closeButtonRect.top,
          previewControlSize,
          previewControlSize,
        ),
      ),
    );
    final controlsBottom = _maxValue(
      closeButtonRect.bottom,
      downloadButtonRect.bottom,
    );
    final documentTopInset = controlsBottom + _controlsDocumentGap;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarDividerColor: navigationBarColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: documentTopInset,
                  left: AppSpacing.xxs,
                  right: AppSpacing.xxs,
                  bottom: AppSpacing.xxs,
                ),
                child: _buildDocument(),
              ),
              Positioned.fill(
                child: PreviewOverlayControls(
                  closeButtonRect: closeButtonRect,
                  downloadButtonRect: downloadButtonRect,
                  isDownloading: _isDownloading,
                  onClose: () => Navigator.pop(context),
                  onDownload: _download,
                  downloadTooltip: 'Descargar PDF',
                ),
              ),
            ],
          ),
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
          mimeType: 'application/pdf',
          bytes: localFile?.bytes,
          localPath: localFile?.path,
          remoteUri: remoteUri,
        ),
      );
      if (saved && mounted) {
        ErrorDisplay.showSuccess(context, 'Se descargo correctamente');
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
            'No fue posible abrir el archivo.',
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

Rect? _globalRect(GlobalKey? key) {
  final renderObject = key?.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}

double _maxValue(double first, double second) =>
    first > second ? first : second;

Rect _localPreviewRect(
  Rect? globalRect, {
  required double safeAreaTop,
  required Rect fallback,
}) {
  if (globalRect == null) return fallback;
  return globalRect.shift(Offset(0, -safeAreaTop));
}
