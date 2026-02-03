import 'package:animal_record/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:animal_record/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:logger/logger.dart';

class MockDio extends Mock implements Dio {}

class MockLogger extends Mock implements Logger {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockDio mockDio;
  late MockLogger mockLogger;

  setUp(() {
    mockDio = MockDio();
    mockLogger = MockLogger();
    dataSource = AuthRemoteDataSourceImpl(dio: mockDio, logger: mockLogger);
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
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
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
      verify(() => mockDio.post('/users', data: tUserModel.toJson())).called(1);
      expect(result, equals(tUserModel));
    });

    test(
      'debe lanzar una excepción cuando el statusCode no sea 200 o 201',
      () async {
        // arrange
        when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: 'Something went wrong',
            statusCode: 404,
            requestOptions: RequestOptions(path: '/users'),
          ),
        );

        // act
        final call = dataSource.signUp(tUserModel);

        // assert
        expect(() => call, throwsA(isA<Exception>()));
      },
    );
  });
}
