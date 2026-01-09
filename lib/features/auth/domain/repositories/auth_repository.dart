import 'package:animal_record/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp(Map<String, dynamic> userData);
}
