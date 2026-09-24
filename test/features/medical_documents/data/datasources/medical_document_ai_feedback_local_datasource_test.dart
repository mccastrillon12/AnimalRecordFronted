import 'package:animal_record/features/medical_documents/data/datasources/medical_document_ai_feedback_local_datasource.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps feedback pending until it is cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dataSource = MedicalDocumentAiFeedbackLocalDataSourceImpl(
      sharedPreferences: preferences,
    );

    expect(
      dataSource.isPending('animal-1', MedicalDocumentCategory.prescription),
      isFalse,
    );

    await dataSource.markPending(
      'animal-1',
      MedicalDocumentCategory.prescription,
    );

    final restoredDataSource = MedicalDocumentAiFeedbackLocalDataSourceImpl(
      sharedPreferences: preferences,
    );
    expect(
      restoredDataSource.isPending(
        'animal-1',
        MedicalDocumentCategory.prescription,
      ),
      isTrue,
    );

    await restoredDataSource.clearPending(
      'animal-1',
      MedicalDocumentCategory.prescription,
    );

    expect(
      restoredDataSource.isPending(
        'animal-1',
        MedicalDocumentCategory.prescription,
      ),
      isFalse,
    );
  });

  test('scopes pending feedback by animal and category', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dataSource = MedicalDocumentAiFeedbackLocalDataSourceImpl(
      sharedPreferences: preferences,
    );

    await dataSource.markPending(
      'animal-1',
      MedicalDocumentCategory.medicalOrder,
    );

    expect(
      dataSource.isPending('animal-1', MedicalDocumentCategory.medicalOrder),
      isTrue,
    );
    expect(
      dataSource.isPending('animal-1', MedicalDocumentCategory.prescription),
      isFalse,
    );
    expect(
      dataSource.isPending('animal-2', MedicalDocumentCategory.medicalOrder),
      isFalse,
    );
  });
}
