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
        isVerified: false,
        departmentId: params.departmentId,
        cityId: params.cityId,
      );

      final result = await remoteDataSource.signUp(userModel);
      return Right(result);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login(LoginParams params) async {
    try {
      final credentials = params.toJson();
      final response = await remoteDataSource.login(credentials);

      final userData = response['user'] ?? response;
      String userId = (userData['id'] ?? '').toString();

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
          } catch (e) {}
        }
      }

      if (userId.isEmpty || userId == 'null') {
        throw Exception(
          'Error del servidor: No se pudo identificar al usuario',
        );
      }

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await tokenStorage.saveUserId(userId);
      }

      final fullProfile = await remoteDataSource.getUserProfile(userId);

      return Right(fullProfile);
    } on UserNotVerifiedException catch (e) {
      return Left(ServerFailure('UserNotVerified:${e.timeRemaining ?? ""}'));
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();

      await tokenStorage.clearTokens();

      return const Right(null);
    } catch (e) {
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
        params.identifier,
        params.code,
      );

      final userData = response['user'] ?? response;
      String userId = (userData['id'] ?? '').toString();

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
          } catch (e) {}
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

      if (accessToken != null) {
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
  Future<Either<Failure, Map<String, dynamic>>> checkAvailability(
    Map<String, dynamic> data,
  ) async {
    try {
      final availabilityMap = await remoteDataSource.checkAvailability(data);
      return Right(availabilityMap);
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
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPin(String identifier) async {
    try {
      await remoteDataSource.forgotPin(identifier);
      return const Right(null);
    } catch (e) {
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

  @override
  Future<Either<Failure, void>> forgotPassword(String identifier) async {
    try {
      await remoteDataSource.forgotPassword(identifier);
      return const Right(null);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String identifier,
    String token,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.resetPassword(identifier, token, newPassword);
      return const Right(null);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, void>> resetPin(
    String identifier,
    String token,
    String newPin,
  ) async {
    try {
      await remoteDataSource.resetPin(identifier, token, newPin);
      return const Right(null);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, bool>> validatePasswordToken(
    String identifier,
    String token,
  ) async {
    try {
      final isValid = await remoteDataSource.validatePasswordToken(
        identifier,
        token,
      );
      return Right(isValid);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, bool>> validatePinToken(
    String identifier,
    String token,
  ) async {
    try {
      final isValid = await remoteDataSource.validatePinToken(
        identifier,
        token,
      );
      return Right(isValid);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProfilePictureUploadUrl(
    String mimeType,
    int fileSize,
  ) async {
    try {
      final data = await remoteDataSource.getProfilePictureUploadUrl(
        mimeType,
        fileSize,
      );
      return Right(data);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> confirmProfilePicture(
    String finalUrl,
  ) async {
    try {
      final user = await remoteDataSource.confirmProfilePicture(finalUrl);
      return Right(user);
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      return Left(ServerFailure(errorMsg));
    }
  }
}
