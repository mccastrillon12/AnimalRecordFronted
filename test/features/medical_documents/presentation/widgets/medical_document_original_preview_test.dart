import 'dart:convert';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  testWidgets('opens local images with the same viewer used by the diary', (
    tester,
  ) async {
    final closeIconKey = GlobalKey();
    final downloadIconKey = GlobalKey();
    final fileSaver = _RecordingFileSaver();
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: GetMedicalDocumentDownloadUriUseCase(
        _DownloadOnlyRepository(),
      ),
      saveOriginalUseCase: SaveMedicalDocumentOriginalUseCase(fileSaver),
    );
    final image = SharedFileEntity(
      path: '',
      name: 'formula.png',
      mimeType: 'image/png',
      type: SharedFileType.image,
      size: 68,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 83,
                left: 311,
                child: Icon(key: closeIconKey, Icons.close, size: 20),
              ),
              Positioned(
                top: 83,
                left: 24,
                child: SizedBox.square(key: downloadIconKey, dimension: 20),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => preview.show(
                    context,
                    localFile: image,
                    mimeType: image.mimeType,
                    closeIconKey: closeIconKey,
                    downloadIconKey: downloadIconKey,
                  ),
                  child: const Text('Ver original'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final sourceCloseRect = tester.getRect(find.byKey(closeIconKey));
    final sourceDownloadRect = tester.getRect(find.byKey(downloadIconKey));
    await tester.tap(find.text('Ver original'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ImagePreviewDialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(PreviewOverlayControls), findsOneWidget);
    expect(find.byTooltip('Descargar imagen'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Cerrar')), sourceCloseRect);
    _expectHeaderDownloadPosition(tester, sourceDownloadRect);
    _expectDocumentImmediatelyBelowControls(
      tester,
      find.byType(InteractiveViewer),
    );
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.fit, BoxFit.contain);
    expect(imageWidget.alignment, Alignment.center);
    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.topLeft, Offset.zero);
    expect(
      dialogRect.size,
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(
      barriers.any((barrier) => barrier.color == AppColors.overlayBlack),
      isTrue,
    );

    await tester.tap(find.byTooltip('Descargar imagen'));
    await tester.pump();

    expect(fileSaver.request?.fileName, 'formula.png');
    expect(fileSaver.request?.mimeType, 'image/png');
    expect(fileSaver.request?.bytes, image.bytes);
    expect(fileSaver.request?.remoteUri, isNull);
    expect(find.text('Se descargo correctamente'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('opens PDFs over the modal overlay and fits the white page', (
    tester,
  ) async {
    final closeIconKey = GlobalKey();
    final downloadIconKey = GlobalKey();
    final fileSaver = _RecordingFileSaver();
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: GetMedicalDocumentDownloadUriUseCase(
        _DownloadOnlyRepository(),
      ),
      saveOriginalUseCase: SaveMedicalDocumentOriginalUseCase(fileSaver),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 37,
                left: 327,
                child: Icon(key: closeIconKey, Icons.close, size: 24),
              ),
              Positioned(
                top: 37,
                left: 24,
                child: SizedBox.square(key: downloadIconKey, dimension: 20),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => preview.show(
                    context,
                    acceptedDocumentId: 'document-1',
                    fileName: 'formula.pdf',
                    mimeType: 'application/pdf',
                    closeIconKey: closeIconKey,
                    downloadIconKey: downloadIconKey,
                  ),
                  child: const Text('Ver PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final sourceCloseRect = tester.getRect(find.byKey(closeIconKey));
    final sourceDownloadRect = tester.getRect(find.byKey(downloadIconKey));
    await tester.tap(find.text('Ver PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(
      barriers.any((barrier) => barrier.color == AppColors.overlayBlack),
      isTrue,
    );
    expect(dialog.backgroundColor, Colors.transparent);
    expect(viewer.params.backgroundColor, Colors.transparent);
    expect(viewer.params.margin, AppSpacing.s);
    expect(viewer.params.pageDropShadow, isNull);
    expect(viewer.params.layoutPages, isNull);
    expect(viewer.params.calculateInitialZoom, isNotNull);
    expect(find.byTooltip('Descargar PDF'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(find.byType(PreviewOverlayControls), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Cerrar')), sourceCloseRect);
    _expectHeaderDownloadPosition(tester, sourceDownloadRect);
    _expectDocumentImmediatelyBelowControls(tester, find.byType(PdfViewer));
    expect(
      find.byKey(const Key('pdf-preview-header-background')),
      findsNothing,
    );
    final closeRect = tester.getRect(find.byTooltip('Cerrar'));
    expect(closeRect.top, greaterThanOrEqualTo(AppSpacing.xl));
    final closeIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byTooltip('Cerrar'),
        matching: find.byIcon(Icons.close),
      ),
    );
    expect(closeIcon.color, AppColors.white);

    await tester.tap(find.byTooltip('Descargar PDF'));
    await tester.pump();

    expect(fileSaver.request?.fileName, 'formula.pdf');
    expect(fileSaver.request?.mimeType, 'application/pdf');
    expect(
      fileSaver.request?.remoteUri,
      Uri.parse('https://example.test/original'),
    );
    expect(find.text('Se descargo correctamente'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

void _expectHeaderDownloadPosition(
  WidgetTester tester,
  Rect sourceDownloadRect,
) {
  final buttonRect = tester.getRect(
    find.byKey(const Key('preview-download-button')),
  );
  expect(buttonRect.topLeft, sourceDownloadRect.topLeft);
  expect(buttonRect.size, const Size.square(24));
  expect(
    tester.widget(find.byKey(const Key('preview-download-button'))),
    isA<SizedBox>(),
  );
  final icon = tester.widget<SvgPicture>(
    find.byKey(const Key('preview-download-icon')),
  );
  expect(icon.width, 24);
  expect(icon.height, 24);
}

void _expectDocumentImmediatelyBelowControls(
  WidgetTester tester,
  Finder documentFinder,
) {
  final documentRect = tester.getRect(documentFinder);
  final downloadRect = tester.getRect(
    find.byKey(const Key('preview-download-button')),
  );
  final closeRect = tester.getRect(find.byTooltip('Cerrar'));
  final controlsBottom = downloadRect.bottom > closeRect.bottom
      ? downloadRect.bottom
      : closeRect.bottom;
  expect(documentRect.top, controlsBottom + 20);
}

class _RecordingFileSaver implements MedicalDocumentFileSaver {
  MedicalDocumentFileSaveRequest? request;

  @override
  Future<bool> save(MedicalDocumentFileSaveRequest request) async {
    this.request = request;
    return true;
  }
}

class _DownloadOnlyRepository implements MedicalDocumentsRepository {
  @override
  void clearCache() {}

  @override
  Future<MedicalFieldCatalog> getFieldCatalog({
    required MedicalDocumentCategory category,
    String locale = 'es-CO',
  }) => throw UnimplementedError();

  @override
  Future<Uri> getDownloadUri(String documentId) async =>
      Uri.parse('https://example.test/original');

  @override
  Future<MedicalDocumentEntity> analyze(
    AnalyzeMedicalDocumentRequest request,
  ) => throw UnimplementedError();

  @override
  Future<MedicalDocumentEntity> getById(String documentId) =>
      throw UnimplementedError();

  @override
  Future<List<MedicalDocumentRejectionReasonEntity>> getRejectionReasons() =>
      throw UnimplementedError();

  @override
  Future<void> submitAiFeedback(MedicalDocumentAiFeedback feedback) =>
      throw UnimplementedError();

  @override
  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) => throw UnimplementedError();

  @override
  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
    bool forceRefresh = false,
  }) => throw UnimplementedError();
}
