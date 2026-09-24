import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

typedef PhotoToJpegConverter = Future<Uint8List> Function(Uint8List bytes);

abstract interface class ManualFilePickerDataSource {
  Future<Map<Object?, Object?>?> pickFromFiles();

  Future<Map<Object?, Object?>?> pickFromPhotos();
}

class ManualFilePickerDataSourceImpl implements ManualFilePickerDataSource {
  final ImagePicker imagePicker;
  final PhotoToJpegConverter photoToJpegConverter;

  ManualFilePickerDataSourceImpl({
    ImagePicker? imagePicker,
    PhotoToJpegConverter? photoToJpegConverter,
  }) : imagePicker = imagePicker ?? ImagePicker(),
       photoToJpegConverter = photoToJpegConverter ?? _convertPhotoToJpeg;

  @override
  Future<Map<Object?, Object?>?> pickFromFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'tif', 'tiff', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    return {
      'path': file.path ?? '',
      'name': file.name,
      'mimeType': _mimeType(file.extension),
      'size': file.size,
      'bytes': file.bytes,
    };
  }

  @override
  Future<Map<Object?, Object?>?> pickFromPhotos() async {
    final file = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return null;
    final bytes = await photoToJpegConverter(await file.readAsBytes());

    return {
      'path': file.path,
      'name': _jpegFileName(file.name),
      'mimeType': 'image/jpeg',
      'size': bytes.length,
      'bytes': bytes,
    };
  }

  static Future<Uint8List> _convertPhotoToJpeg(Uint8List bytes) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1920,
      minHeight: 1920,
      quality: 85,
      format: CompressFormat.jpeg,
    );
  }

  String _jpegFileName(String name) {
    final lastDot = name.lastIndexOf('.');
    final originalBaseName = lastDot > 0 ? name.substring(0, lastDot) : name;
    final baseName = originalBaseName.trim().isEmpty
        ? 'foto'
        : originalBaseName;
    return '$baseName.jpg';
  }

  String _mimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'tif' || 'tiff' => 'image/tiff',
      _ => 'application/octet-stream',
    };
  }
}
