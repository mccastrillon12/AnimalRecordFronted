import 'package:animal_record/features/home/domain/entities/animal_entity.dart';

/// Resolves permissions from current data while preserving historical snapshots.
abstract final class AnimalWritePolicy {
  static bool canWrite({
    required AnimalEntity snapshot,
    Iterable<AnimalEntity>? currentAnimals,
  }) {
    if (snapshot.isHistorical) return false;
    if (currentAnimals == null) return snapshot.canWrite;
    return canWriteAll([snapshot.id], currentAnimals);
  }

  static bool canWriteAll(
    Iterable<String> animalIds,
    Iterable<AnimalEntity> currentAnimals,
  ) {
    final ids = animalIds.toSet();
    if (ids.isEmpty || ids.any((id) => id.trim().isEmpty)) return false;
    final writableIds = currentAnimals
        .where((animal) => animal.canWrite)
        .map((animal) => animal.id)
        .toSet();
    return writableIds.containsAll(ids);
  }
}
