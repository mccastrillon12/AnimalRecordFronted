import 'dart:typed_data';

abstract interface class FileUploader {
  Future<void> upload({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  });
}
