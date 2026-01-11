import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/register_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signUp(RegisterParams params) async {
    try {
      final userModel = UserModel(
        id: params.id,
        name: params.name,
        identificationType: params.identificationType,
        identificationNumber: params.identificationNumber,
        country: params.country,
        city: params.city,
        email: params.email,
        cellPhone: params.cellPhone,
        professionalCard: params.professionalCard,
        animalTypes: params.animalTypes,
        services: params.services,
        isHomeDelivery: params.isHomeDelivery,
        roles: params.roles,
        password: params.password,
      );

      final result = await remoteDataSource.signUp(userModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
