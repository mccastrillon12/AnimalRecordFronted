import 'package:animal_record/features/medical_documents/data/datasources/pending_medical_document_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists every value required to resume the same analysis', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dataSource = PendingMedicalDocumentLocalDataSourceImpl(
      sharedPreferences: preferences,
    );
    final startedAt = DateTime.utc(2026, 8, 8, 12);

    await dataSource.save(
      PendingMedicalDocumentFlow(
        documentId: 'document-1',
        animalIds: const [
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ],
        startedAt: startedAt,
        requestedCategory: MedicalDocumentCategory.clinicalHistory,
      ),
    );

    final restored = dataSource.read();
    expect(restored?.documentId, 'document-1');
    expect(restored?.animalIds, hasLength(2));
    expect(restored?.startedAt, startedAt);
    expect(
      restored?.requestedCategory,
      MedicalDocumentCategory.clinicalHistory,
    );
  });

  test(
    'clears the persisted analysis only when explicitly requested',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final dataSource = PendingMedicalDocumentLocalDataSourceImpl(
        sharedPreferences: preferences,
      );
      await dataSource.save(
        PendingMedicalDocumentFlow(
          documentId: 'document-1',
          animalIds: const ['11111111-1111-4111-8111-111111111111'],
          startedAt: DateTime.utc(2026, 8, 8),
        ),
      );

      await dataSource.clear();

      expect(dataSource.read(), isNull);
    },
  );

  test('ignores an incomplete persisted flow', () async {
    SharedPreferences.setMockInitialValues({
      'PENDING_MEDICAL_DOCUMENT_FLOW':
          '{"documentId":"document-1","animalIds":[],"startedAt":"2026-08-08T00:00:00.000Z"}',
    });
    final preferences = await SharedPreferences.getInstance();
    final dataSource = PendingMedicalDocumentLocalDataSourceImpl(
      sharedPreferences: preferences,
    );

    expect(dataSource.read(), isNull);
  });
}
