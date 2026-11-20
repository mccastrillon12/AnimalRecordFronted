abstract interface class MedicalDocumentWriteAccess {
  Future<void> ensureWritable({
    Iterable<String> animalIds = const [],
    Iterable<String> documentIds = const [],
  });
}
