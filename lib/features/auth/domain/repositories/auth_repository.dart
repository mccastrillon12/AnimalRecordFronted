import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';
import '../entities/register_params.dart';
import '../entities/login_params.dart';
import '../entities/verify_code_params.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp(RegisterParams params);
  Future<Either<Failure, UserEntity>> login(LoginParams params);
  Future<Either<Failure, void>> logout();
  Future<bool> isAuthenticated();
  Future<Either<Failure, UserEntity>> verifyCode(VerifyCodeParams params);
  Future<Either<Failure, void>> resendVerificationCode(String identifier);
  Future<Either<Failure, bool>> checkIdentificationExists(
    String identificationNumber,
  );
  Future<Either<Failure, Map<String, dynamic>>> checkSocialToken(
    String provider,
    String token,
  );
  Future<Either<Failure, UserEntity>> registerSocial(Map<String, dynamic> data);
  Future<Either<Failure, UserEntity>> getUserProfile(String id);
  Future<Either<Failure, UserEntity>> updateUser(
    String id,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  );
  Future<Either<Failure, void>> savePin(String pin);
  Future<Either<Failure, void>> verifyPin(String pin);
  Future<Either<Failure, void>> changePin(String oldPin, String newPin);
  Future<Either<Failure, void>> forgotPin(String identifier);
  Future<Either<Failure, void>> updateBiometricStatus(bool enabled);
  Future<Either<Failure, bool>> getBiometricStatus();
  Future<Either<Failure, void>> forgotPassword(String identifier);
  Future<Either<Failure, void>> resetPassword(
    String identifier,
    String token,
    String newPassword,
  );
  Future<Either<Failure, void>> resetPin(
    String identifier,
    String token,
    String newPin,
  );
  Future<Either<Failure, bool>> validatePasswordToken(
    String identifier,
    String token,
  );
}
