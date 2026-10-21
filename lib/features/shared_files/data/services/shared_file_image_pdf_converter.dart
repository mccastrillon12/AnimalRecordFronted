import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SharedFileImagePdfConverter {
  Future<Uint8List> convert(Uint8List imageBytes) async {
    final document = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    return document.save();
  }
}
