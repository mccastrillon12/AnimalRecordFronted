import 'package:animal_record/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:animal_record/features/auth/data/models/user_model.dart';
import 'package:animal_record/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:logger/logger.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockLogger extends Mock implements Logger {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockLogger mockLogger;

  setUp(() {
    mockApiClient = MockApiClient();
    mockLogger = MockLogger();
    dataSource = AuthRemoteDataSourceImpl(
      apiClient: mockApiClient,
      logger: mockLogger,
    );
  });

  group('signUp', () {
    final tUserModel = UserModel.fromJson({
      'id': '1',
      'name': 'Test',
      'email': 'test@test.com',
      'identificationType': 'CC',
      'identificationNumber': '123',
      'country': 'Col',
      'countryId': 'CO',
      'departmentId': '11',
      'city': 'Bog',
      'cityId': '11001',
      'cellPhone': '123',
      'animalTypes': [],
      'services': [],
      'isHomeDelivery': false,
      'roles': [],
    });

    test('debe realizar una petición POST al endpoint correcto', () async {
      // arrange
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'id': '1',
            'name': 'Test',
            'email': 'test@test.com',
            'identificationType': 'CC',
            'identificationNumber': '123',
            'country': 'Col',
            'countryId': 'CO',
            'departmentId': '11',
            'city': 'Bog',
            'cityId': '11001',
            'cellPhone': '123',
            'animalTypes': [],
            'services': [],
            'isHomeDelivery': false,
            'roles': [],
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/users'),
        ),
      );

      // act
      final result = await dataSource.signUp(tUserModel);

      // assert
      verify(
        () => mockApiClient.post('/users', data: tUserModel.toJson()),
      ).called(1);
      expect(result.id, equals(tUserModel.id));
      expect(result.email, equals(tUserModel.email));
    });

    test('debe propagar la excepción lanzada por ApiClient', () async {
      // arrange
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenThrow(Exception('Error inesperado: \${e.toString()}'));

      // act
      final call = dataSource.signUp;

      // assert
      expect(() => call(tUserModel), throwsA(isA<Exception>()));
    });
  });
}
