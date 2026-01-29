import 'package:dio/dio.dart';
import 'package:animal_record/core/exceptions/user_not_verified_exception.dart';
import 'package:animal_record/core/utils/error_mapper.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(UserModel user);
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<void> verifyCode(String email, String code);
  Future<void> resendVerificationCode(String identifier);
  Future<bool> checkIdentificationExists(String identificationNumber);
  Future<Map<String, dynamic>> checkSocialToken(String provider, String token);
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> signUp(UserModel user) async {
    try {
      final jsonData = user.toJson();

      print('--- DEBUG SIGN UP ---');
      print('URL: /users');
      print('Payload: $jsonData');
      print('----------------------');

      final response = await dio.post('/users', data: jsonData);

      print('--- SIGN UP SUCCESS ---');
      print('Status: ${response.statusCode}');
      print('Response: ${response.data}');
      print('------------------------');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Error en el registro');
      }
    } on DioException catch (e) {
      print('--- SIGN UP DIO ERROR ---');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('Message: ${e.message}');
      print('-------------------------');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      print('--- SIGN UP UNEXPECTED ERROR ---');
      print('Error: $e');
      print('--------------------------------');
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await dio.post('/auth/login', data: credentials);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error en el login');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      }
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        final timeRemaining = data is Map<String, dynamic>
            ? data['timeRemaining']
            : null;
        throw UserNotVerifiedException(timeRemaining: timeRemaining);
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Optional: call backend logout endpoint if exists
      // This would invalidate the refresh token on the server
      await dio.post('/auth/logout');
    } catch (e) {
      // Logout can fail silently - tokens will be cleared locally anyway
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    try {
      final response = await dio.post(
        '/auth/verify',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode != 200) {
        throw Exception('Código de verificación inválido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw Exception('Código de verificación inválido o expirado');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<bool> checkIdentificationExists(String identificationNumber) async {
    try {
      final response = await dio.get(
        '/users/identification/$identificationNumber',
      );

      // If we get a 200 response, the user exists
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      // If we get a 404, the user doesn't exist
      if (e.response?.statusCode == 404) {
        return false;
      }
      // For other errors, throw exception
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> resendVerificationCode(String identifier) async {
    try {
      final response = await dio.post(
        '/auth/resend-code',
        data: {'identifier': identifier},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al reenviar el código');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Identificador inválido');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> checkSocialToken(
    String provider,
    String token,
  ) async {
    try {
      print('--- DEBUG SOCIAL CHECK ---');
      print('Payload: {"provider": "$provider", "token": "$token"}');
      print('---------------------------');

      final response = await dio.post(
        '/auth/social/check',
        data: {'provider': provider, 'token': token},
      );

      print('--- SOCIAL CHECK SUCCESS ---');
      print('Response: ${response.data}');
      print('----------------------------');

      return response.data;
    } on DioException catch (e) {
      print('--- SOCIAL CHECK ERROR ---');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('--------------------------');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data) async {
    try {
      print('--- DEBUG SOCIAL REGISTER ---');
      print('Payload: $data');
      print('------------------------------');

      final response = await dio.post('/auth/social/register', data: data);

      print('--- SOCIAL REGISTER SUCCESS ---');
      print('Response: ${response.data}');
      print('-------------------------------');

      return response.data;
    } on DioException catch (e) {
      print('--- SOCIAL REGISTER ERROR ---');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('------------------------------');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
