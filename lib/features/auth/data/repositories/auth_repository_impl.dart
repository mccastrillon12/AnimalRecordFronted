import 'package:dartz/dartz.dart';
import 'package:animal_record/core/exceptions/user_not_verified_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/register_params.dart';
import '../../domain/entities/login_params.dart';
import '../../domain/entities/verify_code_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<Either<Failure, UserEntity>> signUp(RegisterParams params) async {
    try {
      final userModel = UserModel(
        id: params.id,
        name: params.name,
        identificationType: params.identificationType,
        identificationNumber: params.identificationNumber,
        country: params.country,
        countryId: params.countryId,
        city: params.city,
        email: params.email,
        cellPhone: params.cellPhone,
        professionalCard: params.professionalCard,
        animalTypes: params.animalTypes,
        services: params.services,
        isHomeDelivery: params.isHomeDelivery,
        roles: params.roles,
        authMethod: params.authMethod,
        password: params.password,
      );

      final result = await remoteDataSource.signUp(userModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(LoginParams params) async {
    try {
      final credentials = params.toJson();
      final response = await remoteDataSource.login(credentials);

      // Parse user data from response
      final userData = response['user'] ?? response;
      final userModel = UserModel.fromJson(userData);

      // Store tokens securely
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      return Right(userModel);
    } on UserNotVerifiedException catch (e) {
      // Pass UserNotVerified as a specific failure with timeRemaining
      return Left(ServerFailure('UserNotVerified:${e.timeRemaining ?? ""}'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call backend logout (optional)
      await remoteDataSource.logout();

      // Clear tokens from secure storage
      await tokenStorage.clearTokens();

      return const Right(null);
    } catch (e) {
      // Even if backend logout fails, clear local tokens
      await tokenStorage.clearTokens();
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await tokenStorage.hasTokens();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, void>> verifyCode(VerifyCodeParams params) async {
    try {
      await remoteDataSource.verifyCode(params.email, params.code);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationCode(
    String identifier,
  ) async {
    try {
      await remoteDataSource.resendVerificationCode(identifier);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkIdentificationExists(
    String identificationNumber,
  ) async {
    try {
      final exists = await remoteDataSource.checkIdentificationExists(
        identificationNumber,
      );
      return Right(exists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
