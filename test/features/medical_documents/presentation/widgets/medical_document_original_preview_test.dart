import 'dart:convert';

import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_requests.dart';
import 'package:animal_record/features/medical_documents/domain/repositories/medical_documents_repository.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens local images with the same viewer used by the diary', (
    tester,
  ) async {
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: GetMedicalDocumentDownloadUriUseCase(
        _DownloadOnlyRepository(),
      ),
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
        home: Builder(
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
    );

    await tester.tap(find.text('Ver original'));
    await tester.pump();

    expect(find.byType(ImagePreviewDialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
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
