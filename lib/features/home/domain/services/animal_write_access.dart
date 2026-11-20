/// Verifies current permissions before changing an existing animal or its files.
abstract interface class AnimalWriteAccess {
  Future<void> ensureWritable(Iterable<String> animalIds);
}

class AnimalReadOnlyException implements Exception {
  const AnimalReadOnlyException();

  @override
  String toString() =>
      'El animal está en modo de solo lectura. No se permite modificar su información ni sus archivos.';
}
