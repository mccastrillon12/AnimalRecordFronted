import 'dart:typed_data';
import '../entities/animal_ownership.dart';

abstract interface class HistoricalAnimalPhotoStore {
  void clearMemory();
  Uint8List? peek(HistoricalFileReference photo);
  Future<Uint8List> load(
    HistoricalFileReference photo,
    Future<List<int>> Function() download,
  );
}
