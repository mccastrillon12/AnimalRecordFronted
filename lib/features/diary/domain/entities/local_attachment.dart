class LocalAttachment {
  final String path;
  final String fileName;
  final String mimeType;
  final String fileType;
  final int size;

  const LocalAttachment({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.fileType,
    required this.size,
  });
}
