import 'dart:typed_data';

import 'package:animal_record/features/medical_documents/data/services/medical_document_file_saver_impl.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves provided bytes with a safe PDF file name', () async {
    String? savedName;
    Uint8List? savedBytes;
    final saver = MedicalDocumentFileSaverImpl(
      dio: Dio(),
      saveBytes: ({required fileName, required bytes}) async {
        savedName = fileName;
        savedBytes = bytes;
        return 'saved/document.pdf';
      },
    );
    final sourceBytes = Uint8List.fromList([1, 2, 3]);

    final saved = await saver.save(
      MedicalDocumentFileSaveRequest(
        fileName: 'fórmula: médica',
        bytes: sourceBytes,
      ),
    );

    expect(saved, isTrue);
    expect(savedName, 'fórmula_ médica.pdf');
    expect(savedBytes, same(sourceBytes));
  });

  test('reports cancellation when the save dialog returns no path', () async {
    final saver = MedicalDocumentFileSaverImpl(
      dio: Dio(),
      saveBytes: ({required fileName, required bytes}) async => null,
    );

    final saved = await saver.save(
      MedicalDocumentFileSaveRequest(
        fileName: 'documento.pdf',
        bytes: Uint8List.fromList([1]),
      ),
    );

    expect(saved, isFalse);
  });

  test('preserves an existing image extension without appending pdf', () async {
    String? savedName;
    final saver = MedicalDocumentFileSaverImpl(
      dio: Dio(),
      saveBytes: ({required fileName, required bytes}) async {
        savedName = fileName;
        return 'saved/$fileName';
      },
    );

    final saved = await saver.save(
      MedicalDocumentFileSaveRequest(
        fileName: '15240513993600.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(saved, isTrue);
    expect(savedName, '15240513993600.jpg');
  });
}
