import 'package:animal_record/features/home/data/datasources/animal_remote_datasource.dart';
import 'package:animal_record/features/home/domain/services/animal_write_access.dart';
import 'package:animal_record/features/home/domain/services/animal_write_policy.dart';

class RemoteAnimalWriteAccess implements AnimalWriteAccess {
  final AnimalRemoteDataSource remote;

  const RemoteAnimalWriteAccess(this.remote);

  @override
  Future<void> ensureWritable(Iterable<String> animalIds) async {
    final ids = animalIds.toSet();
    if (ids.isEmpty || ids.any((id) => id.trim().isEmpty)) {
      throw const AnimalReadOnlyException();
    }
    // Transfer flags are guaranteed on the own-animal list. Do not rely on a
    // previously opened form or on a detail response that may omit those flags.
    final animals = await remote.getOwnAnimals();
    if (!AnimalWritePolicy.canWriteAll(ids, animals)) {
      throw const AnimalReadOnlyException();
    }
  }
}
