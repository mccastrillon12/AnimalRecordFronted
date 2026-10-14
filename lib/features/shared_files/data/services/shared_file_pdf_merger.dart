import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

class SharedFilePdfMerger {
  Future<Uint8List> merge(List<Uint8List> documents) async {
    if (documents.isEmpty) {
      throw const FormatException('No hay documentos PDF para combinar.');
    }
    if (documents.length == 1) return documents.single;

    await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
    final opened = <PdfDocument>[];
    try {
      for (var index = 0; index < documents.length; index++) {
        opened.add(
          await PdfDocument.openData(
            documents[index],
            sourceName: 'animal-record-combined-$index.pdf',
          ),
        );
      }
      final target = opened.first;
      target.pages = [for (final document in opened) ...document.pages];
      return target.encodePdf();
    } finally {
      for (final document in opened.reversed) {
        await document.dispose();
      }
    }
  }
}
