import 'dart:convert';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  testWidgets('opens local images with the same viewer used by the diary', (
    tester,
  ) async {
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => preview.show(
                context,
                localFile: image,
                mimeType: image.mimeType,
              ),
              child: const Text('Ver original'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ver original'));
    await tester.pump();

    expect(find.byType(ImagePreviewDialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('opens PDFs over the modal overlay and fits the white page', (
    tester,
  ) async {
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => preview.show(
                context,
                acceptedDocumentId: 'document-1',
                fileName: 'formula.pdf',
                mimeType: 'application/pdf',
              ),
              child: const Text('Ver PDF'),
            ),
          ),
        ),
      ),
    );

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
    expect(viewer.params.calculateInitialZoom, isNotNull);
    expect(find.byTooltip('Descargar PDF'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(
      find.byKey(const Key('pdf-preview-header-background')),
      findsNothing,
    );
    final closeRect = tester.getRect(find.byTooltip('Cerrar'));
    expect(closeRect.top, AppSpacing.xl);
    final closeIcon = tester.widget<Icon>(find.byIcon(Icons.close));
    expect(closeIcon.color, AppColors.white);

    await tester.tap(find.byTooltip('Descargar PDF'));
    await tester.pump();

    expect(fileSaver.request?.fileName, 'formula.pdf');
    expect(
      fileSaver.request?.remoteUri,
      Uri.parse('https://example.test/original'),
    );
  });
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
  Future<MedicalDocumentEntity> review(
    String documentId,
    ReviewMedicalDocumentRequest request,
  ) => throw UnimplementedError();

  @override
  Future<List<MedicalDocumentEntity>> getByAnimal(
    String animalId, {
    MedicalDocumentCategory? category,
  }) => throw UnimplementedError();
}
