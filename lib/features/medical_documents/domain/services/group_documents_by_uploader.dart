import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';

class MedicalDocumentUploaderGroup {
  final String? uploaderId;
  final String? uploaderName;
  final List<MedicalDocumentEntity> documents;

  const MedicalDocumentUploaderGroup({
    required this.uploaderId,
    required this.uploaderName,
    required this.documents,
  });
}

/// Uses authenticated provenance exclusively; never PDF extraction or ownership.
List<MedicalDocumentUploaderGroup> groupDocumentsByUploader(
  Iterable<MedicalDocumentEntity> documents,
) {
  final groups = <String?, List<MedicalDocumentEntity>>{};
  for (final document in documents) {
    groups.putIfAbsent(document.uploadedBy?.id, () => []).add(document);
  }
  return List.unmodifiable(
    groups.entries.map((entry) {
      String? name;
      for (final document in entry.value) {
        final candidate = document.uploadedBy?.name?.trim();
        if (candidate != null && candidate.isNotEmpty) {
          name = candidate;
          break;
        }
      }
      return MedicalDocumentUploaderGroup(
        uploaderId: entry.key,
        uploaderName: name,
        documents: List.unmodifiable(entry.value),
      );
    }),
  );
}
