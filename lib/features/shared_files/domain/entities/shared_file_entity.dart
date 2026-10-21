import 'package:equatable/equatable.dart';
import 'dart:typed_data';

enum SharedFileType { image, pdf, unsupported }

class SharedFileEntity extends Equatable {
  final String path;
  final String name;
  final String mimeType;
  final SharedFileType type;
  final int size;
  final Uint8List? bytes;

  const SharedFileEntity({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.type,
    this.size = 0,
    this.bytes,
  });

  @override
  List<Object?> get props => [path, name, mimeType, type, size, bytes];
}
