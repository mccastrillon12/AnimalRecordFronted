import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(UserModel user);
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<void> verifyCode(String email, String code);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> signUp(UserModel user) async {
    try {
      final jsonData = user.toJson();
      print('=== SENDING TO BACKEND ===');
      print('URL: /users');
      print('Data: $jsonData');

      final response = await dio.post('/users', data: jsonData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('=== BACKEND RESPONSE SUCCESS ===');
        print('Response: ${response.data}');
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Error en el registro');
      }
    } on DioException catch (e) {
      // Extract detailed error message from backend
      String errorMessage = 'Error del servidor';

      if (e.response?.data != null) {
        final data = e.response!.data;

        // Handle different error response formats
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data['error'] != null) {
            errorMessage = data['error'].toString();
          } else if (data['errors'] != null) {
            // Handle validation errors array
            errorMessage = data['errors'].toString();
          }
        } else if (data is String) {
          errorMessage = data;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      print('SignUp Error Details: ${e.response?.data}');
      throw Exception('Error del servidor: $errorMessage');
    } catch (e) {
      print('SignUp Unexpected Error: $e');
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
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Error del servidor: $errorMessage');
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
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Error del servidor: $errorMessage');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
