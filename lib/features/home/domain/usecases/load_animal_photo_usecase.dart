import 'dart:typed_data';
import '../entities/animal_ownership.dart';
import '../repositories/historical_animal_photo_store.dart';
import 'animal_history_usecases.dart';
import 'get_animal_by_id_usecase.dart';

class LoadAnimalPhotoUseCase {
  final HistoricalAnimalPhotoStore photos;
  final DownloadHistoricalFileUseCase downloadFile;
  final GetAnimalByIdUseCase getAnimal;
  const LoadAnimalPhotoUseCase({
    required this.photos,
    required this.downloadFile,
    required this.getAnimal,
  });
  Uint8List? cached(HistoricalFileReference photo) => photos.peek(photo);
  Future<Uint8List> call(HistoricalFileReference photo) =>
      photos.load(photo, () => downloadFile(photo));
  Future<String?> renewCurrentPhoto(String animalId) async => (await getAnimal(
    animalId,
  )).fold((_) => null, (animal) => animal.profilePictureUrl);
}
