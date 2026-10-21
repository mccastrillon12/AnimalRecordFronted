import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MedicalDocumentAiFeedbackLocalDataSource {
  bool isPending(String animalId, MedicalDocumentCategory category);

  Future<void> markPending(String animalId, MedicalDocumentCategory category);

  Future<void> clearPending(String animalId, MedicalDocumentCategory category);
}

class MedicalDocumentAiFeedbackLocalDataSourceImpl
    implements MedicalDocumentAiFeedbackLocalDataSource {
  static const _keyPrefix = 'PENDING_MEDICAL_DOCUMENT_AI_FEEDBACK';

  final SharedPreferences sharedPreferences;

  const MedicalDocumentAiFeedbackLocalDataSourceImpl({
    required this.sharedPreferences,
  });

  @override
  bool isPending(String animalId, MedicalDocumentCategory category) =>
      sharedPreferences.getBool(_key(animalId, category)) ?? false;

  @override
  Future<void> markPending(
    String animalId,
    MedicalDocumentCategory category,
  ) async {
    await sharedPreferences.setBool(_key(animalId, category), true);
  }

  @override
  Future<void> clearPending(
    String animalId,
    MedicalDocumentCategory category,
  ) async {
    await sharedPreferences.remove(_key(animalId, category));
  }

  String _key(String animalId, MedicalDocumentCategory category) =>
      '$_keyPrefix:$animalId:${category.wireValue}';
}
