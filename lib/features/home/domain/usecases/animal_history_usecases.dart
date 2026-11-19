import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import '../entities/animal_entity.dart';
import '../entities/animal_ownership.dart';
import '../repositories/animal_history_repository.dart';
import '../repositories/animal_transfer_repository.dart';
import '../repositories/historical_animal_photo_store.dart';

class DownloadHistoricalFileUseCase {
  final AnimalTransferRepository repository;
  const DownloadHistoricalFileUseCase(this.repository);
  Future<List<int>> call(HistoricalFileReference file) =>
      repository.downloadHistoricalFile(
        periodId: file.periodId,
        publicationHash: file.publicationHash,
        entryId: file.entryId,
        fileId: file.fileId,
      );
}

class LoadHistoricalAnimalUseCase {
  final AnimalHistoryRepository repository;
  final HistoricalAnimalPhotoStore? photos;
  final DownloadHistoricalFileUseCase? downloadFile;
  const LoadHistoricalAnimalUseCase(
    this.repository, {
    this.photos,
    this.downloadFile,
  });

  void useAccount(String accountId) => repository.useAccount(accountId);
  void clear() => repository.clear();

  AnimalEntity? cached(AnimalEntity card, {bool includeEntries = true}) {
    final history = card.ownershipHistory;
    if (!card.isHistorical || history == null) return null;
    final cached = repository.peek(history);
    return cached == null
        ? null
        : repository.restoreAnimal(
            card,
            cached,
            includeEntries: includeEntries,
          );
  }

  Future<AnimalEntity> call(
    AnimalEntity card, {
    bool preloadPhoto = false,
    bool includeEntries = true,
  }) async {
    final reference = card.ownershipHistory;
    if (reference == null) {
      throw const FormatException(
        'No se encontró la publicación del expediente.',
      );
    }
    final history = await repository.load(reference);
    if (preloadPhoto &&
        history.photo != null &&
        photos != null &&
        downloadFile != null) {
      try {
        await photos!.load(history.photo!, () => downloadFile!(history.photo!));
      } catch (_) {
        // An unavailable photo must not prevent reading the animal.
      }
    }
    return repository.restoreAnimal(
      card,
      history,
      includeEntries: includeEntries,
    );
  }
}

class GetHistoricalDiaryUseCase {
  final AnimalHistoryRepository repository;
  const GetHistoricalDiaryUseCase(this.repository);
  Future<List<DiaryEntryEntity>> call(AnimalOwnershipHistory history) async =>
      repository.diary(await repository.load(history));
}

class GetHistoricalDocumentsUseCase {
  final AnimalHistoryRepository repository;
  const GetHistoricalDocumentsUseCase(this.repository);
  Future<List<MedicalDocumentEntity>> call(
    AnimalOwnershipHistory history, {
    MedicalDocumentCategory? category,
  }) async =>
      repository.documents(await repository.load(history), category: category);
}
