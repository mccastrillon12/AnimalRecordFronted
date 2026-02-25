import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:animal_record/core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(UserModel user);
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<Map<String, dynamic>> verifyCode(String email, String code);
  Future<void> resendVerificationCode(String identifier);
  Future<bool> checkIdentificationExists(String identificationNumber);
  Future<Map<String, dynamic>> checkSocialToken(String provider, String token);
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data);
  Future<UserModel> getUserProfile(String id);
  Future<UserModel> updateProfile(String id, Map<String, dynamic> data);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<void> forgotPassword(String identifier);
  Future<void> savePin(String pin);
  Future<void> verifyPin(String pin);
  Future<void> changePin(String oldPin, String newPin);
  Future<void> updateBiometricStatus(bool enabled);
  Future<Map<String, dynamic>> getBiometricStatus();
  Future<void> forgotPin(String identifier);
  Future<void> resetPassword(
    String identifier,
    String token,
    String newPassword,
  );
  Future<void> resetPin(String identifier, String token, String newPin);
  Future<bool> validatePasswordToken(String identifier, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final Logger logger;

  AuthRemoteDataSourceImpl({required this.apiClient, required this.logger});

  @override
  Future<UserModel> signUp(UserModel user) async {
    final response = await apiClient.post('/users', data: user.toJson());
    return UserModel.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    final response = await apiClient.post('/auth/login', data: credentials);
    if (response.data is List) {
      throw Exception('Error del servidor: formato de respuesta inválido');
    }
    return response.data;
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    final response = await apiClient.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  @override
  Future<bool> checkIdentificationExists(String identificationNumber) async {
    try {
      final response = await apiClient.get(
        '/users/identification/$identificationNumber',
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e.toString().contains('404')) return false;
      throw e;
    }
  }

  @override
  Future<void> resendVerificationCode(String identifier) async {
    await apiClient.post('/auth/resend-code', data: {'identifier': identifier});
  }

  @override
  Future<Map<String, dynamic>> checkSocialToken(
    String provider,
    String token,
  ) async {
    final response = await apiClient.post(
      '/auth/social/check',
      data: {'provider': provider, 'token': token},
    );
    if (response.data is List)
      throw Exception('Error del servidor: formato de respuesta inválido');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data) async {
    final response = await apiClient.post('/auth/social/register', data: data);
    if (response.data is List)
      throw Exception('Error del servidor: formato de respuesta inválido');
    return response.data;
  }

  @override
  Future<UserModel> getUserProfile(String id) async {
    final response = await apiClient.get('/users/$id');
    if (response.data is List) throw Exception('Error del servidor');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/users/$id', data: data);
    if (response.data is Map<String, dynamic>) {
      return UserModel.fromJson(response.data);
    }
    return await getUserProfile(id);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await apiClient.post(
      '/auth/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<void> forgotPassword(String identifier) async {
    await apiClient.post(
      '/auth/forgot-password',
      data: {'identifier': identifier},
    );
  }

  @override
  Future<void> savePin(String pin) async {
    await apiClient.post('/auth/pin', data: {'pin': pin});
  }

  @override
  Future<void> verifyPin(String pin) async {
    await apiClient.post('/auth/pin/verify', data: {'pin': pin});
  }

  @override
  Future<void> changePin(String oldPin, String newPin) async {
    await apiClient.put(
      '/auth/pin',
      data: {'oldPin': oldPin, 'newPin': newPin},
    );
  }

  @override
  Future<void> updateBiometricStatus(bool enabled) async {
    await apiClient.patch('/auth/biometric/status', data: {'enable': enabled});
  }

  @override
  Future<Map<String, dynamic>> getBiometricStatus() async {
    final response = await apiClient.get('/auth/biometric/status');
    return response.data;
  }

  @override
  Future<void> forgotPin(String identifier) async {
    await apiClient.post('/auth/forgot-pin', data: {'identifier': identifier});
  }

  @override
  Future<void> resetPassword(
    String identifier,
    String token,
    String newPassword,
  ) async {
    await apiClient.post(
      '/auth/reset-password',
      data: {
        'identifier': identifier,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<bool> validatePasswordToken(String identifier, String token) async {
    try {
      final response = await apiClient.get(
        '/auth/validate-password-token',
        queryParameters: {'identifier': identifier, 'token': token},
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data.toString().trim().toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      if (e.toString().contains('400') || e.toString().contains('401')) {
        return false;
      }
      throw e;
    }
  }

  @override
  Future<void> resetPin(String identifier, String token, String newPin) async {
    await apiClient.post(
      '/auth/reset-pin',
      data: {'identifier': identifier, 'token': token, 'newPin': newPin},
    );
  }
}
