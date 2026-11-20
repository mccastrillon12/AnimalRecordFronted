import 'package:animal_record/core/network/api_client.dart';
import 'package:animal_record/features/home/data/datasources/animal_transfer_remote_datasource.dart';
import 'package:animal_record/features/home/data/datasources/animal_remote_datasource.dart';
import 'package:animal_record/features/home/data/repositories/animal_transfer_repository_impl.dart';
import 'package:animal_record/features/home/data/services/animal_history_snapshot.dart';
import 'package:animal_record/features/home/data/models/animal_data_model.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Api extends Mock implements ApiClient {}

void main() {
  setUpAll(() => registerFallbackValue(Options()));

  test(
    'la compilación normal abre la publicación completa de la ficha transferida',
    () async {
      final api = _Api();
      when(
        () => api.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/animal-ownership-history/period-1',
          ),
          statusCode: 200,
          data: {
            'entries': [
              {
                'entryId': 'animal-entry',
                'kind': 'ANIMAL',
                'data': {
                  'id': 'animal-1',
                  'name': 'Caballito 2',
                  'species': 'EQUINE',
                  'sex': 'MALE',
                  'weight': 350,
                },
                'media': [],
              },
            ],
            'nextCursor': null,
          },
        ),
      );
      final repository = AnimalTransferRepositoryImpl(
        AnimalTransferRemoteDataSource(api),
        animalsRemote: AnimalRemoteDataSourceImpl(apiClient: api),
      );
      const history = AnimalOwnershipHistory(
        periodId: 'period-1',
        publicationHash: 'hash+a/b=',
      );
      final snapshot = await AnimalHistorySnapshot.load(history, repository);
      final animal = AnimalHistorySnapshot.animal(
        AnimalDataModel.fromJson({
          'id': 'animal-1',
          'name': 'Caballito 2',
          'species': 'EQUINE',
          'sex': 'MALE',
        }),
        snapshot,
      );
      expect(animal.weight, 350);
      expect(animal.canWrite, isFalse);
      verify(
        () => api.get<Map<String, dynamic>>(
          '/animal-ownership-history/period-1',
          queryParameters: {'limit': 20, 'publicationHash': 'hash+a/b='},
        ),
      ).called(1);
      verifyNoMoreInteractions(api);
    },
  );

  test(
    'la foto publicada descarga bytes sin exigir activar el menú histórico',
    () async {
      final api = _Api();
      when(
        () => api.get<List<int>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path:
                '/animal-ownership-history/period-1/entries/entry-1/files/photo-1',
          ),
          statusCode: 200,
          data: [1, 2, 3],
          headers: Headers.fromMap({
            'content-length': ['3'],
          }),
        ),
      );
      final remote = AnimalTransferRemoteDataSource(api);
      final bytes = await remote.downloadHistoricalFile(
        periodId: 'period-1',
        publicationHash: 'hash+a/b=',
        entryId: 'entry-1',
        fileId: 'photo-1',
      );
      expect(bytes, [1, 2, 3]);
      final options =
          verify(
                () => api.get<List<int>>(
                  '/animal-ownership-history/period-1/entries/entry-1/files/photo-1',
                  queryParameters: {'publicationHash': 'hash+a/b='},
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      expect(options.responseType, ResponseType.bytes);
      verifyNoMoreInteractions(api);
    },
  );
}
