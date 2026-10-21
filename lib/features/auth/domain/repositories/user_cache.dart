import 'package:animal_record/features/auth/domain/entities/user_entity.dart';

abstract interface class UserCache {
  Future<UserEntity?> read();

  Future<void> save(UserEntity user);
}
