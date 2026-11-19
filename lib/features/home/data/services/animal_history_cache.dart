import 'package:animal_record/features/home/data/services/animal_history_snapshot.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'dart:convert';
import 'package:animal_record/core/cache/bounded_memory_cache.dart';
import 'package:animal_record/features/home/domain/repositories/animal_history_repository.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';

/// A publication is immutable. Keep its complete information for this session.
class AnimalHistoryCache implements AnimalHistoryRepository {
  final AnimalTransferRepository repository;
  final BoundedMemoryCache<(String, String), AnimalOwnershipHistory> _loaded;
  final _pending = <(String, String), Future<AnimalOwnershipHistory>>{};
  String? _accountId;
  int _generation = 0;

  AnimalHistoryCache(
    this.repository, {
    int maxEntries = 64,
    int maxBytes = 12 * 1024 * 1024,
  }) : _loaded = BoundedMemoryCache(
         maxEntries: maxEntries,
         maxBytes: maxBytes,
         sizeOf: _sizeOf,
       );

  static int _sizeOf(AnimalOwnershipHistory history) =>
      (history.entries ?? []).fold(
        256,
        (size, entry) =>
            size +
            utf8.encode(jsonEncode(entry.data)).length * 2 +
            entry.media.length * 256 +
            256,
      );

  @override
  AnimalEntity restoreAnimal(
    AnimalEntity card,
    AnimalOwnershipHistory history, {
    bool includeEntries = true,
  }) => AnimalHistorySnapshot.animal(
    card,
    history,
    includeEntries: includeEntries,
  );
  @override
  List<DiaryEntryEntity> diary(AnimalOwnershipHistory history) =>
      AnimalHistorySnapshot.diary(history);
  @override
  List<MedicalDocumentEntity> documents(
    AnimalOwnershipHistory history, {
    MedicalDocumentCategory? category,
  }) => AnimalHistorySnapshot.documents(history, category: category);

  @override
  void useAccount(String accountId) {
    if (_accountId == accountId) return;
    clear();
    _accountId = accountId;
  }

  @override
  void clear() {
    ++_generation;
    _accountId = null;
    _loaded.clear();
    _pending.clear();
  }

  @override
  AnimalOwnershipHistory? peek(AnimalOwnershipHistory history) =>
      history.isLoaded
      ? history
      : _loaded[(history.periodId, history.publicationHash)];

  @override
  Future<AnimalOwnershipHistory> load(AnimalOwnershipHistory history) async {
    final cached = peek(history);
    if (cached != null) return cached;
    final key = (history.periodId, history.publicationHash);
    final pending = _pending[key];
    if (pending != null) return pending;
    final generation = _generation;
    final request = _fetch(history, generation);
    _pending[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_pending[key], request)) _pending.remove(key);
    }
  }

  Future<AnimalOwnershipHistory> _fetch(
    AnimalOwnershipHistory history,
    int generation,
  ) async {
    final loaded = await AnimalHistorySnapshot.load(history, repository);
    if (generation != _generation) throw StateError('La sesión cambió.');
    if (!loaded.entries!.any((entry) => entry.kind == 'ANIMAL')) {
      throw const FormatException(
        'No se encontró la información del animal en el expediente.',
      );
    }
    _loaded[(history.periodId, history.publicationHash)] = loaded;
    return loaded;
  }
}
