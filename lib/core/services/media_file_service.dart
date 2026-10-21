import 'dart:typed_data';

/// Provides the platform-specific file operations required by upload flows.
///
/// Keeping these operations behind an interface prevents presentation state
/// managers from depending directly on `dart:io` or Flutter plugins.
abstract interface class MediaFileService {
  Future<Uint8List?> compressImage(
    String path, {
    required int minWidth,
    required int minHeight,
    required int quality,
  });

  Future<Uint8List> readBytes(String path);
}
