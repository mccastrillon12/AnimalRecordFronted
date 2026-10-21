import 'dart:convert';
import 'dart:typed_data';

import 'package:animal_record/features/shared_files/data/services/shared_file_image_pdf_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts an original PNG into one PDF page', () async {
    final png = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
        'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    final bytes = await SharedFileImagePdfConverter().convert(png);

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
      1,
    );
  });
}
