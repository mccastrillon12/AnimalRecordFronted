import 'dart:convert';

import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/features/auth/data/models/user_model.dart';
import 'package:animal_record/features/auth/domain/entities/user_entity.dart';
import 'package:animal_record/features/auth/domain/repositories/user_cache.dart';

class UserCacheImpl implements UserCache {
  final TokenStorage tokenStorage;

  const UserCacheImpl(this.tokenStorage);

  @override
  Future<UserEntity?> read() async {
    final cachedUser = await tokenStorage.getUserData();
    if (cachedUser == null) return null;

    try {
      final json = jsonDecode(cachedUser) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(UserEntity user) {
    final model = user is UserModel
        ? user
        : UserModel(
            id: user.id,
            name: user.name,
            identificationType: user.identificationType,
            identificationNumber: user.identificationNumber,
            country: user.country,
            countryId: user.countryId,
            departmentId: user.departmentId,
            city: user.city,
            cityId: user.cityId,
            address: user.address,
            email: user.email,
            cellPhone: user.cellPhone,
            professionalCard: user.professionalCard,
            animalTypes: user.animalTypes,
            services: user.services,
            isHomeDelivery: user.isHomeDelivery,
            roles: user.roles,
            authMethod: user.authMethod,
            isVerified: user.isVerified,
            profilePicture: user.profilePicture,
            securityLastUpdated: user.securityLastUpdated,
          );

    return tokenStorage.saveUserData(jsonEncode(model.toJson()));
  }
}
