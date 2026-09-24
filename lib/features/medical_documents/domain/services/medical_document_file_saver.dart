import 'dart:typed_data';

class MedicalDocumentFileSaveRequest {
  final String fileName;
  final String mimeType;
  final Uint8List? bytes;
  final String? localPath;
  final Uri? remoteUri;

  const MedicalDocumentFileSaveRequest({
    required this.fileName,
    this.mimeType = 'application/octet-stream',
    this.bytes,
    this.localPath,
    this.remoteUri,
  });
}

abstract interface class MedicalDocumentFileSaver {
  Future<bool> save(MedicalDocumentFileSaveRequest request);
}
