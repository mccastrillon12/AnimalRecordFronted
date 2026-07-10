import 'package:equatable/equatable.dart';

enum SharedFileType { image, pdf }

class SharedFileEntity extends Equatable {
  final String path;
  final String name;
  final String mimeType;
  final SharedFileType type;

  const SharedFileEntity({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.type,
  });

  @override
  List<Object?> get props => [path, name, mimeType, type];
}
