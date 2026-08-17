import 'dart:io';
import 'package:animal_record/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _controlsDocumentGap = 20.0;
const previewControlSize = 20.0;

class ImagePreviewDialog extends StatefulWidget {
  final String imageUrl;
  final Uint8List? imageBytes;
  final Future<void> Function()? onDownload;
  final Rect? closeIconRect;
  final Rect? downloadIconRect;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.onDownload,
    this.closeIconRect,
    this.downloadIconRect,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final navigationBarColor = Color.alphaBlend(
      AppColors.overlayBlack,
      AppColors.white,
    );
    final fallbackTop = MediaQuery.paddingOf(context).top + AppSpacing.l;
    final closeButtonRect =
        widget.closeIconRect ??
        Rect.fromLTWH(
          MediaQuery.sizeOf(context).width - AppSpacing.l - previewControlSize,
          fallbackTop,
          previewControlSize,
          previewControlSize,
        );
    final downloadButtonRect = widget.onDownload == null
        ? null
        : widget.downloadIconRect ??
              Rect.fromLTWH(
                AppSpacing.l,
                closeButtonRect.top,
                previewControlSize,
                previewControlSize,
              );
    final controlsBottom = _maxValue(
      closeButtonRect.bottom,
      downloadButtonRect?.bottom ?? closeButtonRect.bottom,
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              key: const Key('image-preview-background'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.l,
                documentTopInset,
                AppSpacing.l,
                AppSpacing.l,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child:
                    widget.imageBytes != null && widget.imageBytes!.isNotEmpty
                    ? Image.memory(
                        widget.imageBytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _errorPlaceholder(),
                      )
                    : widget.imageUrl.startsWith('http') ||
                          widget.imageUrl.startsWith('https')
                    ? CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _errorPlaceholder(),
                      )
                    : Image.file(
                        File(widget.imageUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _errorPlaceholder(),
                      ),
              ),
            ),

            Positioned.fill(
              child: PreviewOverlayControls(
                closeButtonRect: closeButtonRect,
                downloadButtonRect: downloadButtonRect,
                isDownloading: _isDownloading,
                onClose: () => Navigator.of(context).pop(),
                onDownload: widget.onDownload == null ? null : _download,
                downloadTooltip: 'Descargar imagen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder() => const Center(
    child: Icon(Icons.broken_image, color: Colors.white, size: 48),
  );

  Future<void> _download() async {
    final onDownload = widget.onDownload;
    if (onDownload == null) return;
    setState(() => _isDownloading = true);
    try {
      await onDownload();
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
}

class PreviewDownloadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String tooltip;
  final Size? size;

  const PreviewDownloadButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.tooltip,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('preview-download-button'),
      width: size?.width ?? AppSpacing.iconSizeMedium,
      height: size?.height ?? AppSpacing.iconSizeMedium,
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryFrances,
                ),
              )
            : SvgPicture.asset(
                AppIcons.receiveSquare,
                key: const Key('preview-download-icon'),
                width: size?.shortestSide ?? 32,
                height: size?.shortestSide ?? 32,
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 243, 240, 240),
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }
}

class PreviewOverlayControls extends StatelessWidget {
  final Rect closeButtonRect;
  final Rect? downloadButtonRect;
  final bool isDownloading;
  final VoidCallback onClose;
  final VoidCallback? onDownload;
  final String downloadTooltip;

  const PreviewOverlayControls({
    super.key,
    required this.closeButtonRect,
    required this.downloadButtonRect,
    required this.isDownloading,
    required this.onClose,
    required this.onDownload,
    required this.downloadTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: closeButtonRect,
          child: IconButton(
            onPressed: isDownloading ? null : onClose,
            icon: const Icon(Icons.close, color: AppColors.white),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(closeButtonRect.size),
            iconSize: closeButtonRect.shortestSide,
            tooltip: 'Cerrar',
          ),
        ),
        if (downloadButtonRect case final rect?)
          Positioned.fromRect(
            rect: rect,
            child: PreviewDownloadButton(
              isLoading: isDownloading,
              onPressed: onDownload!,
              tooltip: downloadTooltip,
              size: rect.size,
            ),
          ),
      ],
    );
  }
}

double _maxValue(double first, double second) =>
    first > second ? first : second;
