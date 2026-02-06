import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:animal_record/core/exceptions/user_not_verified_exception.dart';
import 'package:animal_record/core/utils/error_mapper.dart';
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
  Future<void> savePin(String pin);
  Future<void> verifyPin(String pin);
  Future<void> changePin(String oldPin, String newPin);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final Logger logger;

  AuthRemoteDataSourceImpl({required this.dio, required this.logger});

  @override
  Future<UserModel> signUp(UserModel user) async {
    try {
      final jsonData = user.toJson();

      logger.d('''
--- DEBUG SIGN UP ---
URL: /users
Payload: $jsonData
----------------------
''');

      final response = await dio.post('/users', data: jsonData);

      logger.i('''
--- SIGN UP SUCCESS ---
Status: ${response.statusCode}
Response: ${response.data}
------------------------
''');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Error en el registro');
      }
    } on DioException catch (e) {
      logger.e('''
--- SIGN UP DIO ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
Message: ${e.message}
-------------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      logger.e('''
--- SIGN UP UNEXPECTED ERROR ---
Error: $e
--------------------------------
''');
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await dio.post('/auth/login', data: credentials);

      logger.d('''
--- DEBUG LOGIN ---
Status: ${response.statusCode}
Data Type: ${response.data.runtimeType}
Data: ${response.data}
-------------------
''');

      if (response.statusCode == 200) {
        // Validate response is an object, not an array
        if (response.data is List) {
          logger.e(
            '❌ ERROR: Backend returning array for login instead of single object',
          );
          throw Exception('Error del servidor: formato de respuesta inválido');
        }

        if (response.data is! Map<String, dynamic>) {
          throw Exception('Error del servidor: formato de respuesta inválido');
        }

        return response.data as Map<String, dynamic>;
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
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await dio.post(
        '/auth/verify',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is! Map<String, dynamic>) {
          // If backend returns just "OK" string or something else, we can't extract tokens.
          // But let's assume it returns JSON.
          // If it returns empty body but 200 OK, we have a problem (no tokens).
          // Let's return the data as is.
          return response.data is Map<String, dynamic>
              ? response.data
              : <String, dynamic>{};
        }
        return response.data as Map<String, dynamic>;
      } else {
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
      logger.d('''
--- DEBUG SOCIAL CHECK ---
Payload: {"provider": "$provider", "token": "$token"}
---------------------------
''');

      final response = await dio.post(
        '/auth/social/check',
        data: {'provider': provider, 'token': token},
      );

      logger.i('''
--- SOCIAL CHECK SUCCESS ---
Data Type: ${response.data.runtimeType}
Response: ${response.data}
----------------------------
''');

      // Validate response is an object, not an array
      if (response.data is List) {
        logger.e(
          '❌ ERROR: Backend returning array for social check instead of single object',
        );
        throw Exception('Error del servidor: formato de respuesta inválido');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Error del servidor: formato de respuesta inválido');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e('''
--- SOCIAL CHECK ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
--------------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> registerSocial(Map<String, dynamic> data) async {
    try {
      logger.d('''
--- DEBUG SOCIAL REGISTER ---
Payload: $data
------------------------------
''');

      final response = await dio.post('/auth/social/register', data: data);

      logger.i('''
--- SOCIAL REGISTER SUCCESS ---
Data Type: ${response.data.runtimeType}
Response: ${response.data}
-------------------------------
''');

      // Validate response is an object, not an array
      if (response.data is List) {
        logger.e(
          '❌ ERROR: Backend returning array for social register instead of single object',
        );
        throw Exception('Error del servidor: formato de respuesta inválido');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Error del servidor: formato de respuesta inválido');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e('''
--- SOCIAL REGISTER ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
------------------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    }
  }

  @override
  Future<UserModel> getUserProfile(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw Exception('Error interno: El ID del usuario está vacío');
      }

      final response = await dio.get('/users/$id');

      logger.d('''
--- DEBUG GET USER PROFILE ---
Requested User ID: $id
Status: ${response.statusCode}
Data Type: ${response.data.runtimeType}
Data: ${response.data}
------------------------------
''');

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        // Validate that backend returns a single object, not an array
        if (data is List) {
          logger.e(
            '❌ ERROR: Backend still returning array instead of single user object',
          );
          throw Exception(
            'Error del servidor: se esperaba un usuario único pero se recibió un array',
          );
        }

        if (data is! Map<String, dynamic>) {
          throw Exception('Error del servidor: formato de respuesta inválido');
        }

        // Validate that the returned user ID matches the requested ID
        final returnedId = data['id']?.toString() ?? '';
        if (returnedId != id) {
          logger.w(
            '⚠️ WARNING: Returned user ID ($returnedId) does not match requested ID ($id)',
          );
        }

        logger.i('✓ Successfully retrieved user profile for ID: $returnedId');
        return UserModel.fromJson(data);
      } else {
        throw Exception('Error al obtener el perfil del usuario');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<UserModel> updateProfile(String id, Map<String, dynamic> data) async {
    try {
      logger.d('''
--- DEBUG UPDATE PROFILE ---
ID: $id
Payload: $data
----------------------------
''');

      final response = await dio.put('/users/$id', data: data);

      logger.i('''
--- UPDATE PROFILE SUCCESS ---
Status: ${response.statusCode}
Response: ${response.data}
----------------------------
''');

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          return UserModel.fromJson(responseData);
        } else {
          // Fallback if structure is different
          // For now assume standard user return
          return await getUserProfile(id);
        }
      } else {
        throw Exception('Error al actualizar el perfil');
      }
    } on DioException catch (e) {
      logger.e('''
--- UPDATE PROFILE ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
--------------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      logger.d('''
--- DEBUG CHANGE PASSWORD ---
URL: /auth/change-password
-----------------------------
''');

      final response = await dio.post(
        '/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al cambiar la contraseña');
      }
    } on DioException catch (e) {
      logger.e('''
--- CHANGE PASSWORD ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
-----------------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> savePin(String pin) async {
    try {
      logger.d('''
--- DEBUG SAVE PIN ---
URL: /auth/pin
Payload: {"pin": "$pin"}
----------------------
''');

      final response = await dio.post('/auth/pin', data: {'pin': pin});

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al guardar el PIN');
      }

      logger.i('''
--- SAVE PIN SUCCESS ---
Status: ${response.statusCode}
------------------------
''');
    } on DioException catch (e) {
      logger.e('''
--- SAVE PIN ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
----------------------
''');
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> verifyPin(String pin) async {
    try {
      logger.d('''
--- DEBUG VERIFY PIN ---
URL: /auth/pin/verify
Payload: {"pin": "$pin"}
------------------------
''');

      final response = await dio.post('/auth/pin/verify', data: {'pin': pin});

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('PIN incorrecto');
      }

      logger.i('''
--- VERIFY PIN SUCCESS ---
Status: ${response.statusCode}
--------------------------
''');
    } on DioException catch (e) {
      logger.e('''
--- VERIFY PIN ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
------------------------
''');
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw Exception('PIN incorrecto. Inténtalo de nuevo.');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> changePin(String oldPin, String newPin) async {
    try {
      logger.d('''
--- DEBUG CHANGE PIN ---
URL: /auth/pin
Payload: {"oldPin": "$oldPin", "newPin": "$newPin"}
------------------------
''');

      final response = await dio.put(
        '/auth/pin',
        data: {'oldPin': oldPin, 'newPin': newPin},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al cambiar PIN');
      }

      logger.i('''
--- CHANGE PIN SUCCESS ---
Status: ${response.statusCode}
--------------------------
''');
    } on DioException catch (e) {
      logger.e('''
--- CHANGE PIN ERROR ---
Status: ${e.response?.statusCode}
Data: ${e.response?.data}
------------------------
''');
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw Exception('PIN actual incorrecto. Inténtalo de nuevo.');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
