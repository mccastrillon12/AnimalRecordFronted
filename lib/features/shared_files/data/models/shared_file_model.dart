import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';
import 'dart:typed_data';

class SharedFileModel extends SharedFileEntity {
  const SharedFileModel({
    required super.path,
    required super.name,
    required super.mimeType,
    required super.type,
    super.size,
    super.bytes,
  });

  factory SharedFileModel.fromMap(Map<Object?, Object?> map) {
    final name = map['name']?.toString() ?? '';
    final mimeType = _normalizedMimeType(
      map['mimeType']?.toString() ?? '',
      name,
    );
    final type = mimeType == 'application/pdf'
        ? SharedFileType.pdf
        : mimeType.startsWith('image/')
        ? SharedFileType.image
        : SharedFileType.unsupported;
    return SharedFileModel(
      path: map['path']?.toString() ?? '',
      name: name,
      mimeType: mimeType,
      type: type,
      size: int.tryParse(map['size']?.toString() ?? '') ?? 0,
      bytes: map['bytes'] as Uint8List?,
    );
  }

  static String _normalizedMimeType(String mimeType, String name) {
    final normalized = mimeType.toLowerCase();
    if (normalized.isNotEmpty && normalized != 'application/octet-stream') {
      return normalized;
    }

    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'tif' || 'tiff' => 'image/tiff',
      'pdf' => 'application/pdf',
      _ => normalized,
    };
  }
}
