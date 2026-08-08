import 'dart:convert';

import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/features/auth/data/repositories/user_cache_impl.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late UserCacheImpl cache;

  const user = UserEntity(
    id: 'user-1',
    name: 'Ana',
    identificationType: 'CC',
    identificationNumber: '123',
    country: 'Colombia',
    countryId: 'CO',
    departmentId: '11',
    city: 'Bogotá',
    cityId: '11001',
    email: 'ana@example.com',
    cellPhone: '3000000000',
    animalTypes: [],
    services: [],
    isHomeDelivery: false,
    roles: ['OWNER'],
    authMethod: 'EMAIL',
    isVerified: true,
  );

  setUp(() {
    tokenStorage = MockTokenStorage();
    cache = UserCacheImpl(tokenStorage);
  });

  test('serializa mediante la capa data y conserva el payload actual', () async {
    when(() => tokenStorage.saveUserData(any())).thenAnswer((_) async {});

    await cache.save(user);

    final encoded = verify(
      () => tokenStorage.saveUserData(captureAny()),
    ).captured.single as String;
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    expect(json['id'], user.id);
    expect(json['identificationType'], 'cc');
    expect(json['countryId'], user.countryId);
  });

  test('convierte el JSON cacheado a una entidad de dominio', () async {
    when(() => tokenStorage.getUserData()).thenAnswer(
      (_) async => jsonEncode({
        'id': user.id,
        'name': user.name,
        'identificationType': user.identificationType,
        'identificationNumber': user.identificationNumber,
        'country': user.country,
        'countryId': user.countryId,
        'departmentId': user.departmentId,
        'city': user.city,
        'cityId': user.cityId,
        'email': user.email,
        'cellPhone': user.cellPhone,
        'animalTypes': user.animalTypes,
        'services': user.services,
        'isHomeDelivery': user.isHomeDelivery,
        'roles': user.roles,
        'authMethod': user.authMethod,
        'isVerified': user.isVerified,
      }),
    );

    final result = await cache.read();

    expect(result, isA<UserEntity>());
    expect(result?.id, user.id);
    expect(result?.email, user.email);
    expect(result?.isVerified, user.isVerified);
  });

  test('ignora un cache corrupto sin propagar excepciones', () async {
    when(
      () => tokenStorage.getUserData(),
    ).thenAnswer((_) async => 'no-es-json');

    expect(await cache.read(), isNull);
  });
}
