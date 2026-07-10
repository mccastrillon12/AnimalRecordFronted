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
  Future<Map<String, dynamic>> checkAvailability(Map<String, dynamic> data);
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
  Future<bool> validatePinToken(String identifier, String token);
  Future<Map<String, dynamic>> getProfilePictureUploadUrl(
    String mimeType,
    int fileSize,
  );
  Future<UserModel> confirmProfilePicture(String finalUrl);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final Logger logger;

  AuthRemoteDataSourceImpl({required this.apiClient, required this.logger});

  @override
  Future<UserModel> signUp(UserModel user) async {
    final body = user.toJson();
    final response = await apiClient.post('/users', data: body);
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
  Future<Map<String, dynamic>> verifyCode(
    String identifier,
    String code,
  ) async {
    final response = await apiClient.post(
      '/auth/verify',
      data: {'identifier': identifier, 'code': code},
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
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> checkAvailability(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/users/check-availability', data: data);
      
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is bool) {
        // Si el API retorna un booleano directo (true=disponible, false=ocupado)
        // Lo mapeamos a la primera llave enviada para que la UI sepa qué campo falló
        final key = data.keys.isNotEmpty ? data.keys.first : 'email';
        return {key: response.data};
      }
      return {};
    } catch (e) {
      // Si recibimos un 409 (Conflict/Duplicate) desde el ApiClient, 
      // lo interpretamos como que el dato NO está disponible.
      if (e.toString().contains('409') || e.toString().contains('registrado')) {
        final key = data.keys.isNotEmpty ? data.keys.first : 'email';
        return {key: false};
      }
      rethrow;
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
    if (response.data is List) {
      throw Exception('Error del servidor: formato de respuesta inválido');
    }
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data) async {
    final response = await apiClient.post('/auth/social/register', data: data);
    if (response.data is List) {
      throw Exception('Error del servidor: formato de respuesta inválido');
    }
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
      rethrow;
    }
  }

  @override
  Future<bool> validatePinToken(String identifier, String token) async {
    try {
      final response = await apiClient.get(
        '/auth/validate-pin-token',
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
      rethrow;
    }
  }

  @override
  Future<void> resetPin(String identifier, String token, String newPin) async {
    await apiClient.post(
      '/auth/reset-pin',
      data: {'identifier': identifier, 'token': token, 'newPin': newPin},
    );
  }

  @override
  Future<Map<String, dynamic>> getProfilePictureUploadUrl(
    String mimeType,
    int fileSize,
  ) async {
    final response = await apiClient.get(
      '/users/me/profile-picture/upload-url',
      queryParameters: {'mimeType': mimeType, 'fileSize': fileSize.toString()},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<UserModel> confirmProfilePicture(String finalUrl) async {
    final response = await apiClient.patch(
      '/users/me/profile-picture',
      data: {'finalUrl': finalUrl},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
