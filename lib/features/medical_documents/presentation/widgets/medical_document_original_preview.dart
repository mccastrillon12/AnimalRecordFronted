import 'dart:async';
import 'dart:ui' as ui;

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
    String? searchText,
  }) async {
    final remoteUriLoader = localFile == null && acceptedDocumentId != null
        ? () => getDownloadUriUseCase(acceptedDocumentId)
        : null;
    final isPdf = mimeType.toLowerCase() == 'application/pdf';

    if (isPdf) {
      final loadingOverlay = remoteUriLoader == null
          ? null
          : OverlayEntry(
              builder: (_) => const Positioned.fill(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ModalBarrier(
                        color: Colors.transparent,
                        dismissible: false,
                      ),
                    ),
                    Center(child: _PdfLoadingIndicator()),
                  ],
                ),
              ),
            );
      var loadingVisible = loadingOverlay != null;
      if (loadingOverlay != null) Overlay.of(context).insert(loadingOverlay);
      void dismissLoading() {
        final overlay = loadingOverlay;
        if (!loadingVisible || overlay == null) return;
        loadingVisible = false;
        overlay.remove();
        overlay.dispose();
      }

      try {
        Uri? initialRemoteUri;
        var initialRemoteLoadFailed = false;
        if (remoteUriLoader != null) {
          try {
            initialRemoteUri = await remoteUriLoader();
          } catch (_) {
            initialRemoteLoadFailed = true;
          }
          if (!context.mounted) return;
        }
        Future<void> openDialog() {
          final closeIconRect = _globalRect(closeIconKey);
          final downloadIconRect = _globalRect(downloadIconKey);
          return showDialog<void>(
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
              searchText: searchText,
              initialRemoteUri: initialRemoteUri,
              initialRemoteLoadFailed: initialRemoteLoadFailed,
            ),
          );
        }

        if (initialRemoteUri != null) {
          final reference = PdfDocumentRefUri(initialRemoteUri);
          final opened = await reference.resolveListenable().useDocument<bool>((
            _,
          ) async {
            dismissLoading();
            if (!context.mounted) return false;
            await openDialog();
            return true;
          });
          if (opened == true) return;
          initialRemoteUri = null;
          initialRemoteLoadFailed = true;
        }
        dismissLoading();
        if (!context.mounted) return;
        await openDialog();
        return;
      } finally {
        dismissLoading();
      }
    }

    final remoteUri = remoteUriLoader == null ? null : await remoteUriLoader();
    if (!context.mounted) return;
    final closeIconRect = _globalRect(closeIconKey);
    final downloadIconRect = _globalRect(downloadIconKey);
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
  final String? searchText;
  final Uri? initialRemoteUri;
  final bool initialRemoteLoadFailed;

  const _PdfPreviewDialog({
    required this.localFile,
    required this.remoteUriLoader,
    required this.fileName,
    required this.closeIconRect,
    required this.downloadIconRect,
    required this.saveOriginalUseCase,
    required this.searchText,
    required this.initialRemoteUri,
    required this.initialRemoteLoadFailed,
  });

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  static const _controlsDocumentGap = 20.0;
  late final _viewerParams = PdfViewerParams(
    margin: AppSpacing.s,
    backgroundColor: Colors.transparent,
    pageDropShadow: null,
    calculateInitialZoom: _fitPageWidth,
    onViewerReady: _onViewerReady,
    onDocumentLoadFinished: (_, succeeded) {
      if (!succeeded) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _finishLoading());
      }
    },
    onInteractionStart: (_) => _userInteracted = true,
    pagePaintCallbacks: [_paintSearchResult],
  );

  final _viewerController = PdfViewerController();
  late Future<Uri?> _remoteUriFuture;
  bool _isDownloading = false;
  bool _didStartSearch = false;
  bool _userInteracted = false;
  bool _retryingRemoteLoad = false;
  bool _isPdfReady = false;
  List<PdfPageTextRange> _highlightedWords = const [];

  @override
  void initState() {
    super.initState();
    _remoteUriFuture =
        widget.initialRemoteUri != null || widget.initialRemoteLoadFailed
        ? Future.value(widget.initialRemoteUri)
        : _loadRemoteUri();
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
    if (!_retryingRemoteLoad) {
      if (widget.initialRemoteUri case final uri?) {
        return _buildViewer(remoteUri: uri);
      }
      if (widget.initialRemoteLoadFailed) {
        return _PdfLoadError(onRetry: _retryLoad);
      }
    }

    return FutureBuilder<Uri?>(
      future: _remoteUriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: _PdfLoadingIndicator());
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
      return _observeWheelScroll(
        PdfViewer.data(
          bytes,
          sourceName: localFile!.name,
          controller: _viewerController,
          params: _viewerParams,
        ),
      );
    }
    if (localFile != null && localFile.path.isNotEmpty) {
      return _observeWheelScroll(
        PdfViewer.file(
          localFile.path,
          controller: _viewerController,
          params: _viewerParams,
        ),
      );
    }
    if (remoteUri != null) {
      return _observeWheelScroll(
        PdfViewer.uri(
          remoteUri,
          controller: _viewerController,
          params: _viewerParams,
        ),
      );
    }
    return _PdfLoadError(onRetry: _retryLoad);
  }

  Widget _observeWheelScroll(PdfViewer viewer) => Stack(
    fit: StackFit.expand,
    children: [
      Listener(onPointerSignal: (_) => _userInteracted = true, child: viewer),
      if (!_isPdfReady)
        const Positioned.fill(
          child: AbsorbPointer(child: Center(child: _PdfLoadingIndicator())),
        ),
    ],
  );

  void _retryLoad() {
    _didStartSearch = false;
    _userInteracted = false;
    _highlightedWords = const [];
    _retryingRemoteLoad = true;
    _isPdfReady = false;
    setState(() => _remoteUriFuture = _loadRemoteUri());
  }

  void _onViewerReady(PdfDocument document, PdfViewerController controller) {
    final searchText = widget.searchText?.trim();
    if (searchText == null || searchText.isEmpty) {
      _finishLoading();
      return;
    }
    if (_didStartSearch) return;
    _didStartSearch = true;
    unawaited(_runInitialSearch(document, controller, searchText));
  }

  void _finishLoading() {
    if (mounted && !_isPdfReady) setState(() => _isPdfReady = true);
  }

  Future<void> _runInitialSearch(
    PdfDocument document,
    PdfViewerController controller,
    String searchText,
  ) async {
    try {
      await _locateAndHighlight(document, controller, searchText);
    } catch (_) {
      // The PDF stays usable when text extraction is unavailable.
    } finally {
      _finishLoading();
    }
  }

  Future<void> _locateAndHighlight(
    PdfDocument document,
    PdfViewerController controller,
    String searchText,
  ) async {
    if (document.pages.any((page) => !page.isLoaded)) {
      await document.events.firstWhere(
        (event) => event is PdfDocumentLoadCompleteEvent,
      );
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        !controller.isReady ||
        !identical(controller.document, document)) {
      return;
    }
    final targetWords = _pdfWords(searchText);
    if (targetWords.isEmpty) return;
    final contentWords = targetWords
        .where((word) => !_commonSearchWords.contains(word.normalized))
        .toList(growable: false);
    final comparisonWords = contentWords.isEmpty ? targetWords : contentWords;
    final counts = <String, int>{};
    for (final word in comparisonWords) {
      counts.update(word.normalized, (count) => count + 1, ifAbsent: () => 1);
    }
    final highlightCounts = <String, int>{};
    for (final word in targetWords) {
      highlightCounts.update(
        word.normalized,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final groupedSearch = searchText.contains('\n');
    final searchLines = searchText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final applicationDate = searchLines.length > 1
        ? _parseVaccinationSearchDate(searchLines[1])
        : null;
    final vaccineNameWords = applicationDate == null
        ? const <_PdfWord>[]
        : _pdfWords(searchLines.first);
    final windowWords = targetWords.length * 2;
    final maxWindowWords = windowWords < 12 ? 12 : windowWords;
    _PdfSearchMatch? bestOrdered;
    _PdfSearchMatch? bestOverlap;
    _PdfSearchMatch? bestVaccination;

    for (final page in document.pages) {
      try {
        final pageText = await page.loadStructuredText();
        if (!mounted ||
            !controller.isReady ||
            !identical(controller.document, document)) {
          return;
        }
        final pageWords = _pdfWords(pageText.fullText);
        if (applicationDate != null && vaccineNameWords.isNotEmpty) {
          final vaccination = _bestVaccinationDateMatch(
            pageText,
            pageWords,
            vaccineNameWords,
            applicationDate,
            counts,
            highlightCounts,
            maxWindowWords,
          );
          if (vaccination != null &&
              (bestVaccination == null ||
                  vaccination.wordCount > bestVaccination.wordCount)) {
            bestVaccination = vaccination;
          }
        }
        final ordered = _bestOrderedMatch(pageText, pageWords, targetWords);
        if (ordered != null &&
            (bestOrdered == null ||
                ordered.wordCount > bestOrdered.wordCount)) {
          bestOrdered = ordered;
        }
        if (applicationDate == null &&
            ordered?.wordCount == targetWords.length) {
          break;
        }

        final overlap = _bestWindowMatch(
          pageText,
          pageWords,
          counts,
          highlightCounts,
          maxWindowWords,
        );
        if (overlap != null &&
            (bestOverlap == null ||
                overlap.wordCount > bestOverlap.wordCount)) {
          bestOverlap = overlap;
        }
      } catch (_) {
        if (!mounted || !controller.isReady) return;
      }
    }

    final orderedThreshold = targetWords.length <= 2
        ? 1
        : (targetWords.length / 3).ceil();
    final best = bestVaccination ??
        (groupedSearch && bestOverlap != null
        ? bestOverlap
        : bestOrdered != null && bestOrdered.wordCount >= orderedThreshold
        ? bestOrdered
        : bestOverlap ?? bestOrdered);
    if (best == null ||
        best.highlightedWords.isEmpty ||
        !mounted ||
        !controller.isReady ||
        !identical(controller.document, document)) {
      return;
    }
    final orderedFirst = best.highlightedWords.first;
    final orderedLast = best.highlightedWords.last;
    final overlapFirst = bestOverlap?.highlightedWords.first;
    final overlapLast = bestOverlap?.highlightedWords.last;
    final highlightedMatch = bestVaccination ??
        (bestOverlap != null &&
            bestOverlap.wordCount > best.wordCount &&
            overlapFirst!.pageNumber == orderedFirst.pageNumber &&
            overlapFirst.start <= orderedLast.end &&
            overlapLast!.end >= orderedFirst.start
        ? bestOverlap
        : best);
    _highlightedWords = highlightedMatch.highlightedWords;
    controller.invalidate();

    if (_userInteracted) return;

    final firstWord = highlightedMatch.highlightedWords.first;
    final firstBounds = firstWord.bounds;
    final documentRect = controller.calcRectForRectInsidePage(
      pageNumber: firstWord.pageNumber,
      rect: firstBounds,
    );
    final pageRect = controller.layout.pageLayouts[firstWord.pageNumber - 1];
    final visibleHeight = controller.viewSize.height / controller.currentZoom;
    final centerY = pageRect.height <= visibleHeight
        ? pageRect.center.dy
        : (documentRect.top + visibleHeight * 0.3).clamp(
            pageRect.top + visibleHeight / 2,
            pageRect.bottom - visibleHeight / 2,
          );
    await controller.goTo(
      controller.calcMatrixFor(
        Offset(pageRect.center.dx, centerY),
        zoom: controller.currentZoom,
      ),
      duration: Duration.zero,
    );
  }

  void _paintSearchResult(ui.Canvas canvas, Rect pageRect, PdfPage page) {
    if (_highlightedWords.isEmpty ||
        _highlightedWords.first.pageNumber != page.pageNumber) {
      return;
    }
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2;
    for (final word in _highlightedWords) {
      final rect = word.bounds.toRectInDocument(page: page, pageRect: pageRect);
      if (rect.width <= 0 || rect.height <= 0) continue;
      final underlineY = rect.bottom - 1;
      canvas.drawLine(
        Offset(rect.left, underlineY),
        Offset(rect.right, underlineY),
        paint,
      );
    }
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

class _PdfLoadingIndicator extends StatelessWidget {
  const _PdfLoadingIndicator();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 36,
    height: 36,
    child: CircularProgressIndicator(
      color: AppColors.primaryFrances,
      semanticsLabel: 'Cargando PDF',
    ),
  );
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

const _commonSearchWords = {
  'a',
  'al',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'by',
  'con',
  'de',
  'del',
  'el',
  'en',
  'es',
  'for',
  'from',
  'in',
  'is',
  'it',
  'la',
  'las',
  'lo',
  'los',
  'o',
  'of',
  'on',
  'or',
  'para',
  'por',
  'que',
  'se',
  'su',
  'sus',
  'that',
  'the',
  'this',
  'to',
  'un',
  'una',
  'was',
  'with',
  'y',
};

const _foldedSearchLetters = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
};

class _PdfWord {
  final String normalized;
  final int start;
  final int end;

  const _PdfWord(this.normalized, this.start, this.end);
}

class _PdfSearchMatch {
  final List<PdfPageTextRange> highlightedWords;
  final int wordCount;

  const _PdfSearchMatch(this.highlightedWords, this.wordCount);
}

List<_PdfWord> _pdfWords(String text) => [
  for (final match in RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ0-9]+').allMatches(text))
    _PdfWord(
      match
          .group(0)!
          .toLowerCase()
          .split('')
          .map((letter) => _foldedSearchLetters[letter] ?? letter)
          .join(),
      match.start,
      match.end,
    ),
];

DateTime? _parseVaccinationSearchDate(String value) {
  final match = RegExp(
    r'^(\d{1,4})[/-](\d{1,2})[/-](\d{2,4})$',
  ).firstMatch(value);
  if (match == null) return null;
  final first = int.parse(match.group(1)!);
  final second = int.parse(match.group(2)!);
  final third = int.parse(match.group(3)!);
  if (match.group(1)!.length == 4) {
    return _validSearchDate(first, second, third);
  }
  if (match.group(3)!.length != 4) return null;
  return second > 12
      ? _validSearchDate(third, first, second)
      : _validSearchDate(third, second, first);
}

DateTime? _validSearchDate(int year, int month, int day) {
  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

({int year, int first, int second, bool yearFirst})? _pdfDateAt(
  String text,
  List<_PdfWord> words,
  int index,
) {
  if (index + 2 >= words.length) return null;
  final firstWord = words[index];
  final secondWord = words[index + 1];
  final thirdWord = words[index + 2];
  final first = int.tryParse(firstWord.normalized);
  final second = int.tryParse(secondWord.normalized);
  final third = int.tryParse(thirdWord.normalized);
  if (first == null || second == null || third == null) return null;
  final separator = RegExp(r'^\s*[/.-]\s*$');
  if (!separator.hasMatch(text.substring(firstWord.end, secondWord.start)) ||
      !separator.hasMatch(text.substring(secondWord.end, thirdWord.start))) {
    return null;
  }
  if (firstWord.normalized.length == 4 &&
      _validSearchDate(first, second, third) != null) {
    return (year: first, first: second, second: third, yearFirst: true);
  }
  if (thirdWord.normalized.length != 4 ||
      (_validSearchDate(third, first, second) == null &&
          _validSearchDate(third, second, first) == null)) {
    return null;
  }
  return (year: third, first: first, second: second, yearFirst: false);
}

_PdfSearchMatch? _bestVaccinationDateMatch(
  PdfPageText pageText,
  List<_PdfWord> pageWords,
  List<_PdfWord> vaccineNameWords,
  DateTime applicationDate,
  Map<String, int> targetCounts,
  Map<String, int> highlightCounts,
  int maxWindowWords,
) {
  final minimumNameWords = (vaccineNameWords.length * 0.6).ceil();
  _PdfSearchMatch? best;
  for (var start = 0; start < pageWords.length; start++) {
    var nameWordCount = 0;
    while (nameWordCount < vaccineNameWords.length &&
        start + nameWordCount < pageWords.length &&
        pageWords[start + nameWordCount].normalized ==
            vaccineNameWords[nameWordCount].normalized) {
      nameWordCount++;
    }
    if (nameWordCount < minimumNameWords) continue;

    var blockEnd = start + 120 < pageWords.length
        ? start + 120
        : pageWords.length;
    for (var index = start + nameWordCount; index < blockEnd; index++) {
      if (const {'vaccination', 'vacunacion', 'vacuna'}.contains(
        pageWords[index].normalized,
      )) {
        blockEnd = index;
        break;
      }
    }
    int? firstDateIndex;
    final dateSearchEnd = start + 55 < blockEnd ? start + 55 : blockEnd;
    for (var index = start + nameWordCount;
        index + 2 < dateSearchEnd;
        index++) {
      if (_pdfDateAt(pageText.fullText, pageWords, index) != null) {
        firstDateIndex = index;
        break;
      }
    }
    if (firstDateIndex == null) continue;
    final pdfDate = _pdfDateAt(pageText.fullText, pageWords, firstDateIndex)!;
    final matchesDate = pdfDate.year == applicationDate.year &&
        (pdfDate.yearFirst
            ? pdfDate.first == applicationDate.month &&
                pdfDate.second == applicationDate.day
            : (pdfDate.first == applicationDate.day &&
                    pdfDate.second == applicationDate.month) ||
                (pdfDate.second == applicationDate.day &&
                    pdfDate.first == applicationDate.month));
    if (!matchesDate) continue;

    final overlap = _bestWindowMatch(
      pageText,
      pageWords.sublist(start, blockEnd),
      targetCounts,
      highlightCounts,
      maxWindowWords,
    );
    final ranges = <int, PdfPageTextRange>{};
    for (final range in overlap?.highlightedWords ?? const <PdfPageTextRange>[]) {
      ranges[range.start] = range;
    }
    for (var index = start; index < start + nameWordCount; index++) {
      final word = pageWords[index];
      ranges[word.start] = PdfPageTextRange(
        pageText: pageText,
        start: word.start,
        end: word.end,
      );
    }
    for (var index = firstDateIndex; index < firstDateIndex + 3; index++) {
      final word = pageWords[index];
      ranges[word.start] = PdfPageTextRange(
        pageText: pageText,
        start: word.start,
        end: word.end,
      );
    }
    final highlightedWords = ranges.values.toList()
      ..sort((left, right) => left.start.compareTo(right.start));
    final candidate = _PdfSearchMatch(
      highlightedWords,
      overlap?.wordCount ?? nameWordCount + 3,
    );
    if (best == null || candidate.wordCount > best.wordCount) {
      best = candidate;
    }
  }
  return best;
}

_PdfSearchMatch? _bestOrderedMatch(
  PdfPageText pageText,
  List<_PdfWord> pageWords,
  List<_PdfWord> targetWords,
) {
  if (pageWords.isEmpty || targetWords.isEmpty) return null;
  final targetPositions = <String, List<int>>{};
  for (var index = 0; index < targetWords.length; index++) {
    targetPositions
        .putIfAbsent(targetWords[index].normalized, () => [])
        .add(index);
  }
  final runLengths = List<int>.filled(targetWords.length, 0);
  final lastPageIndexes = List<int>.filled(targetWords.length, -2);
  var bestLength = 0;
  var bestEnd = -1;

  for (var pageIndex = 0; pageIndex < pageWords.length; pageIndex++) {
    final positions = targetPositions[pageWords[pageIndex].normalized];
    if (positions == null) continue;
    for (var position = positions.length - 1; position >= 0; position--) {
      final targetIndex = positions[position];
      final previousIndex = targetIndex - 1;
      final length =
          previousIndex >= 0 && lastPageIndexes[previousIndex] == pageIndex - 1
          ? runLengths[previousIndex] + 1
          : 1;
      runLengths[targetIndex] = length;
      lastPageIndexes[targetIndex] = pageIndex;
      if (length > bestLength) {
        bestLength = length;
        bestEnd = pageIndex;
      }
    }
  }

  if (bestLength == 0) return null;
  return _PdfSearchMatch([
    for (var index = bestEnd - bestLength + 1; index <= bestEnd; index++)
      PdfPageTextRange(
        pageText: pageText,
        start: pageWords[index].start,
        end: pageWords[index].end,
      ),
  ], bestLength);
}

_PdfSearchMatch? _bestWindowMatch(
  PdfPageText pageText,
  List<_PdfWord> words,
  Map<String, int> targetCounts,
  Map<String, int> highlightCounts,
  int maxWindowWords,
) {
  if (words.isEmpty) return null;
  final windowCounts = <String, int>{};
  var windowStart = 0;
  var matchedWords = 0;
  var bestCount = 0;
  var bestSpanWords = words.length + 1;
  var bestStart = 0;
  var bestEnd = 0;

  for (var end = 0; end < words.length; end++) {
    final word = words[end].normalized;
    final allowed = targetCounts[word] ?? 0;
    if (allowed > 0) {
      final current = windowCounts[word] ?? 0;
      if (current < allowed) matchedWords++;
      windowCounts[word] = current + 1;
    }

    if (end - windowStart + 1 > maxWindowWords) {
      final outgoing = words[windowStart++].normalized;
      final outgoingAllowed = targetCounts[outgoing] ?? 0;
      if (outgoingAllowed > 0) {
        final current = windowCounts[outgoing]!;
        if (current <= outgoingAllowed) matchedWords--;
        if (current == 1) {
          windowCounts.remove(outgoing);
        } else {
          windowCounts[outgoing] = current - 1;
        }
      }
    }

    if (matchedWords > 0 &&
        (matchedWords > bestCount ||
            (matchedWords == bestCount && bestSpanWords > matchedWords))) {
      final spanWords = _matchingWordSpan(
        words,
        windowStart,
        end,
        targetCounts,
      );
      if (matchedWords > bestCount || spanWords < bestSpanWords) {
        bestCount = matchedWords;
        bestSpanWords = spanWords;
        bestStart = windowStart;
        bestEnd = end;
      }
    }
  }

  if (bestCount == 0) return null;
  final scoringCounts = <String, int>{};
  int? firstIndex;
  int? lastIndex;
  for (var index = bestStart; index <= bestEnd; index++) {
    final word = words[index];
    final allowed = targetCounts[word.normalized] ?? 0;
    if (allowed == 0) continue;
    final current = scoringCounts[word.normalized] ?? 0;
    if (current >= allowed) continue;
    scoringCounts[word.normalized] = current + 1;
    firstIndex ??= index;
    lastIndex = index;
  }
  if (firstIndex == null || lastIndex == null) return null;
  final highlightedWords = <PdfPageTextRange>[];
  final usedHighlightCounts = <String, int>{};
  for (var index = firstIndex; index <= lastIndex; index++) {
    final word = words[index];
    final allowed = highlightCounts[word.normalized] ?? 0;
    if (allowed == 0) continue;
    final current = usedHighlightCounts[word.normalized] ?? 0;
    if (current >= allowed) continue;
    usedHighlightCounts[word.normalized] = current + 1;
    highlightedWords.add(
      PdfPageTextRange(pageText: pageText, start: word.start, end: word.end),
    );
  }
  return _PdfSearchMatch(highlightedWords, bestCount);
}

int _matchingWordSpan(
  List<_PdfWord> words,
  int start,
  int end,
  Map<String, int> targetCounts,
) {
  final usedCounts = <String, int>{};
  int? first;
  var last = start;
  for (var index = start; index <= end; index++) {
    final word = words[index].normalized;
    final allowed = targetCounts[word] ?? 0;
    if (allowed == 0) continue;
    final current = usedCounts[word] ?? 0;
    if (current >= allowed) continue;
    usedCounts[word] = current + 1;
    first ??= index;
    last = index;
  }
  return first == null ? 0 : last - first + 1;
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
