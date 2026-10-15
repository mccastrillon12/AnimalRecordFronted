import 'dart:typed_data';

abstract interface class MedicalDocumentFileLoader {
  Future<Uint8List> load(Uri remoteUri);
}
