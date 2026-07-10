import 'package:animal_record/features/shared_files/domain/entities/shared_file_entity.dart';

class SharedFileModel extends SharedFileEntity {
  const SharedFileModel({
    required super.path,
    required super.name,
    required super.mimeType,
    required super.type,
  });

  factory SharedFileModel.fromMap(Map<Object?, Object?> map) {
    final mimeType = map['mimeType']?.toString() ?? '';
    return SharedFileModel(
      path: map['path']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      mimeType: mimeType,
      type: mimeType == 'application/pdf'
          ? SharedFileType.pdf
          : SharedFileType.image,
    );
  }
}
