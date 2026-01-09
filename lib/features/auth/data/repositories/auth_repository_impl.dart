import '../../domain/repositories/auth_repository.dart';

import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> signUp(Map<String, dynamic> userData) async {
    // Aquí llamamos al DataSource que ya creaste
    return await remoteDataSource.signUp(userData);
  }
}
