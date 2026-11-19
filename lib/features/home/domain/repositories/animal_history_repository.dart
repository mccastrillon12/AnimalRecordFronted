import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import '../entities/animal_entity.dart';
import '../entities/animal_ownership.dart';

abstract interface class AnimalHistoryRepository {
  void useAccount(String accountId);
  void clear();
  AnimalOwnershipHistory? peek(AnimalOwnershipHistory history);
  Future<AnimalOwnershipHistory> load(AnimalOwnershipHistory history);
  AnimalEntity restoreAnimal(
    AnimalEntity card,
    AnimalOwnershipHistory history, {
    bool includeEntries = true,
  });
  List<DiaryEntryEntity> diary(AnimalOwnershipHistory history);
  List<MedicalDocumentEntity> documents(
    AnimalOwnershipHistory history, {
    MedicalDocumentCategory? category,
  });
}
