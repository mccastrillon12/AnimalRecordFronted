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
    final mimeType = map['mimeType']?.toString() ?? '';
    final type = mimeType == 'application/pdf'
        ? SharedFileType.pdf
        : mimeType.startsWith('image/')
        ? SharedFileType.image
        : SharedFileType.unsupported;
    return SharedFileModel(
      path: map['path']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mimeType: mimeType,
      type: type,
      size: int.tryParse(map['size']?.toString() ?? '') ?? 0,
      bytes: map['bytes'] as Uint8List?,
    );
  }
}
