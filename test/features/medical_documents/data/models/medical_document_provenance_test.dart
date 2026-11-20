import 'package:animal_record/features/home/data/services/animal_history_snapshot.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/medical_documents/data/models/medical_document_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/services/group_documents_by_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const acceptedDocument = {
    'id': 'document-1',
    'ownerId': 'new-owner',
    'status': 'ACCEPTED',
    'finalCategory': 'CLINICAL_HISTORY',
    'createdAt': '2026-11-18T10:00:00Z',
    'acceptedAt': '2026-11-18T10:05:00Z',
    'uploadedBy': {
      'id': 'original-uploader',
      'name': 'Responsable original',
      'uploadedAt': '2026-11-18T10:00:00Z',
    },
  };

  test('accepted documents group by uploader regardless of current owner', () {
    final document = MedicalDocumentModel.fromJson(acceptedDocument);
    final group = groupDocumentsByUploader([document]).single;

    expect(document.status, MedicalDocumentStatus.accepted);
    expect(document.acceptedAt, DateTime.utc(2026, 11, 18, 10, 5));
    expect(group.uploaderId, 'original-uploader');
    expect(group.uploaderName, 'Responsable original');
  });

  test('transfer snapshots preserve uploader when provided by the backend', () {
    final documents = AnimalHistorySnapshot.documents(
      const AnimalOwnershipHistory(
        periodId: 'period-1',
        publicationHash: 'hash-1',
        entries: [
          HistoricalEntry(
            entryId: 'document-1',
            kind: 'MEDICAL_DOCUMENT',
            data: acceptedDocument,
            media: [],
          ),
        ],
      ),
      category: MedicalDocumentCategory.clinicalHistory,
    );
    final group = groupDocumentsByUploader(documents).single;

    expect(documents.single.readOnly, isTrue);
    expect(group.uploaderId, 'original-uploader');
    expect(group.uploaderName, 'Responsable original');
  });

  test(
    'missing uploader cannot be recovered from owner or clinical content',
    () {
      final json = Map<String, dynamic>.from(acceptedDocument)
        ..remove('uploadedBy');
      json['validatedExtraction'] = {
        'owner': {'name': 'Tutor del PDF'},
        'issuer': {'name': 'Veterinario del PDF'},
      };
      final document = MedicalDocumentModel.fromJson(json);
      final group = groupDocumentsByUploader([document]).single;

      expect(document.uploadedBy, isNull);
      expect(group.uploaderId, isNull);
      expect(group.uploaderName, isNull);
      expect(group.documents, [document]);
    },
  );
}
