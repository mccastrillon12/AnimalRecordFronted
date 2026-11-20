import 'package:animal_record/features/home/data/datasources/animal_transfer_remote_datasource.dart';
import 'package:animal_record/features/home/data/datasources/animal_remote_datasource.dart';
import 'package:animal_record/features/home/data/repositories/animal_transfer_repository_impl.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _TransferDataSource extends Mock
    implements AnimalTransferRemoteDataSource {}

class _AnimalDataSource extends Mock implements AnimalRemoteDataSource {}

void main() {
  test(
    'carga edades exactas, rangos y resúmenes anteriores desde el detalle',
    () async {
      final remote = _TransferDataSource();
      final repo = AnimalTransferRepositoryImpl(
        remote,
        animalsRemote: _AnimalDataSource(),
      );
      const baseItem = {
        'animalId': '7f7c6044-7b59-4271-8552-a48f56ec41e4',
        'animalName': 'Spot',
        'animalCode': 'AR-C041',
        'status': 'PENDING',
      };
      when(() => remote.getDetail('transfer-1')).thenAnswer(
        (_) async => {
          'request': {'id': 'transfer-1', 'version': 1, 'status': 'PENDING'},
          'items': [
            {
              ...baseItem,
              'id': 'item-1',
              'animalBreed': 'Labrador',
              'animalSex': 'MALE',
              'animalSpecies': 'CANINE',
              'animalProfilePictureUrl': 'https://example.com/spot.jpg',
              'animalAge': {'type': 'EXACT', 'months': 0},
            },
            {
              ...baseItem,
              'id': 'item-2',
              'animalAge': {
                'type': 'APPROXIMATE',
                'minMonths': 12,
                'maxMonths': 24,
              },
            },
            {...baseItem, 'id': 'item-3'},
          ],
        },
      );

      final items = (await repo.getDetail('transfer-1')).page.items;
      expect(items[0].animalBreed, 'Labrador');
      expect(items[0].animalSex, 'MALE');
      expect(items[0].animalSpecies, 'CANINE');
      expect(items[0].animalImageUrl, 'https://example.com/spot.jpg');
      expect(items[0].animalAge, const ExactTransferAnimalAge(0));
      expect(items[1].animalAge, const ApproximateTransferAnimalAge(12, 24));
      expect(items[2].animalAge, isNull);
      expect(items[2].animalBreed, isNull);
      expect(items[2].animalSex, isNull);
      expect(items[2].animalImageUrl, isNull);
    },
  );
}
