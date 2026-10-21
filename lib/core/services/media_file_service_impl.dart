import 'dart:io';
import 'dart:typed_data';

import 'package:animal_record/core/services/media_file_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaFileServiceImpl implements MediaFileService {
  const MediaFileServiceImpl();

  @override
  Future<Uint8List?> compressImage(
    String path, {
    required int minWidth,
    required int minHeight,
    required int quality,
  }) {
    return FlutterImageCompress.compressWithFile(
      path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.jpeg,
    );
  }

  @override
  Future<Uint8List> readBytes(String path) => File(path).readAsBytes();
}
