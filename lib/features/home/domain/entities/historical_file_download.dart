/// A complete historical file, delivered through the authenticated API.
class HistoricalFileDownload {
  final List<int> bytes;
  final String? fileName;
  final String? mimeType;

  const HistoricalFileDownload({
    required this.bytes,
    this.fileName,
    this.mimeType,
  });
}
