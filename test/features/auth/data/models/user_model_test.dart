import 'package:flutter_test/flutter_test.dart';
import 'package:animal_record/features/auth/data/models/user_model.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';

void main() {
  const tUserModel = UserModel(
    id: '1',
    name: 'Test User',
    identificationType: 'CC',
    identificationNumber: '12345',
    country: 'Colombia',
    departmentId: '11',
    city: 'Bogota',
    cityId: '11001',
    email: 'test@test.com',
    cellPhone: '3001234567',
    professionalCard: 'TP123',
    animalTypes: ['Perro', 'Gato'],
    services: ['Consulta'],
    isHomeDelivery: true,
    roles: ['Veterinario'],
    authMethod: 'EMAIL',
    countryId: 'CO',
    isVerified: true,
  );

  group('UserModel', () {
    test('debe ser una subclase de UserEntity', () {
      expect(tUserModel, isA<UserEntity>());
    });

    test(
      'fromJson debe devolver un modelo válido cuando el JSON tiene todos los campos',
      () {
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'name': 'Test User',
          'identificationType': 'CC',
          'identificationNumber': '12345',
          'country': 'Colombia',
          'departmentId': '11',
          'city': 'Bogota',
          'cityId': '11001',
          'email': 'test@test.com',
          'cellPhone': '3001234567',
          'professionalCard': 'TP123',
          'animalTypes': ['Perro', 'Gato'],
          'services': ['Consulta'],
          'isHomeDelivery': true,
          'roles': ['Veterinario'],
          'authMethod': 'EMAIL',
          'countryId': 'CO',
          'isVerified': true,
        };

        final result = UserModel.fromJson(jsonMap);

        expect(result, tUserModel);
      },
    );

    test('toJson debe devolver un mapa JSON con los datos correctos', () {
      final result = tUserModel.toJson();

      final expectedMap = {
        'id': '1',
        'name': 'Test User',
        'identificationType': 'CC',
        'identificationNumber': '12345',
        'country': 'Colombia',
        'departmentId': '11',
        'city': 'Bogota',
        'cityId': '11001',
        'email': 'test@test.com',
        'cellPhone': '3001234567',
        'professionalCard': 'TP123',
        'animalTypes': ['Perro', 'Gato'],
        'services': ['Consulta'],
        'isHomeDelivery': true,
        'roles': ['Veterinario'],
        'authMethod': 'EMAIL',
        'isVerified': true,
      };

      expect(result, expectedMap);
    });
  });
}
