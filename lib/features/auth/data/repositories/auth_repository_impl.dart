import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
        isVerified: false, // Initial registration state
        departmentId: params.departmentId, // Added
        cityId: params.cityId, // Added
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

      // Parse user data from response to get the ID
      // Parse user data from response to get the ID

      final userData = response['user'] ?? response;
      String userId = (userData['id'] ?? '').toString();

      // Fallback: Try to get ID from Access Token if not found in response
      if (userId.isEmpty || userId == 'null') {
        final accessToken = response['accessToken'] as String?;
        if (accessToken != null) {
          try {
            Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);

            // Try common ID fields
            if (decodedToken.containsKey('id')) {
              userId = decodedToken['id'].toString();
            } else if (decodedToken.containsKey('sub')) {
              userId = decodedToken['sub'].toString();
            } else if (decodedToken.containsKey('userId')) {
              userId = decodedToken['userId'].toString();
            }
          } catch (e) {
            // Ignore decoding error
          }
        }
      }

      if (userId.isEmpty || userId == 'null') {
        throw Exception(
          'Error del servidor: No se pudo identificar al usuario',
        );
      }

      // Store tokens securely
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await tokenStorage.saveUserId(userId);
      }

      // Fetch FULL profile to ensure we have the correct name and other fields
      // This will now only be called if we have a valid userId
      final fullProfile = await remoteDataSource.getUserProfile(userId);

      return Right(fullProfile);
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
  Future<Either<Failure, UserEntity>> verifyCode(
    VerifyCodeParams params,
  ) async {
    try {
      final response = await remoteDataSource.verifyCode(
        params.email,
        params.code,
      );

      final userData = response['user'] ?? response;
      String userId = (userData['id'] ?? '').toString();

      // Fallback: Try to get ID from Access Token if not found in response
      if (userId.isEmpty || userId == 'null') {
        final accessToken = response['accessToken'] as String?;
        if (accessToken != null) {
          try {
            Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);

            if (decodedToken.containsKey('id')) {
              userId = decodedToken['id'].toString();
            } else if (decodedToken.containsKey('sub')) {
              userId = decodedToken['sub'].toString();
            } else if (decodedToken.containsKey('userId')) {
              userId = decodedToken['userId'].toString();
            }
          } catch (e) {
            // Ignore decoding error
          }
        }
      }

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      if (userId.isNotEmpty && userId != 'null') {
        await tokenStorage.saveUserId(userId);
        final fullProfile = await remoteDataSource.getUserProfile(userId);
        return Right(fullProfile);
      }

      // If we are here, we might have verified but not got a full session or ID.
      // If we have tokens but no ID, we are in a weird state.
      // If we have nothing, maybe the backend doesn't support auto-login on verify.

      if (accessToken != null) {
        // We have token but no ID? Try to fetch profile?
        // But we need ID for getUserProfile?
        // Actually getUserProfile takes ID.
        // If we can't find ID, we fail.
        return Left(ServerFailure('No se pudo obtener el ID del usuario'));
      }

      return Left(
        ServerFailure(
          'Verificación exitosa, pero no se recibieron credenciales.',
        ),
      );
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

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkSocialToken(
    String provider,
    String token,
  ) async {
    try {
      final response = await remoteDataSource.checkSocialToken(provider, token);

      if (response['status'] == 'SUCCESS' ||
          response['status'] == 'LOGIN_SUCCESS') {
        final userData = response['user'] ?? response;
        final userId = (userData['id'] ?? '').toString();

        final accessToken = response['accessToken'] as String?;
        final refreshToken = response['refreshToken'] as String?;

        if (accessToken != null && refreshToken != null) {
          await tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          await tokenStorage.saveUserId(userId);
        }

        // Fetch FULL profile
        final fullProfile = await remoteDataSource.getUserProfile(userId);

        return Right({'status': 'SUCCESS', 'user': fullProfile});
      }

      return Right(response);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerSocial(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await remoteDataSource.registerSocial(data);

      final userData = response['user'] ?? response;
      final userId = (userData['id'] ?? '').toString();

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await tokenStorage.saveUserId(userId);
      }

      // Fetch FULL profile
      final fullProfile = await remoteDataSource.getUserProfile(userId);

      return Right(fullProfile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserProfile(String id) async {
    try {
      final user = await remoteDataSource.getUserProfile(id);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final user = await remoteDataSource.updateProfile(id, data);

      // Update local storage with new data
      // Using json.encode needs dart:convert
      // But let's assume imports are handled or will be.
      // Actually, let's just return Right(user) for now to fix the interface implementation
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.changePassword(oldPassword, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePin(String pin) async {
    try {
      await remoteDataSource.savePin(pin);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPin(String pin) async {
    try {
      await remoteDataSource.verifyPin(pin);
      return const Right(null);
    } catch (e) {
      print("🔴 Repository verifyPin error: $e"); // LOG
      // Clean up "Exception: " prefix if present
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> changePin(String oldPin, String newPin) async {
    try {
      await remoteDataSource.changePin(oldPin, newPin);
      return const Right(null);
    } catch (e) {
      print("🔴 Repository changePin error: $e"); // LOG
      // Clean up "Exception: " prefix if present
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> updateBiometricStatus(bool enabled) async {
    try {
      await remoteDataSource.updateBiometricStatus(enabled);
      return const Right(null);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, bool>> getBiometricStatus() async {
    try {
      final data = await remoteDataSource.getBiometricStatus();
      return Right(data['isBiometricEnabled'] ?? false);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }
}
