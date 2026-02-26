import 'package:dio/dio.dart';
import 'package:animal_record/core/exceptions/user_not_verified_exception.dart';
import 'package:animal_record/core/utils/error_mapper.dart';
import 'package:logger/logger.dart';

class ApiClient {
  final Dio dio;
  final Logger logger;

  ApiClient({required this.dio, required this.logger});

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () =>
          dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () => dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () => dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () => dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _execute(
      () => dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> _execute<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      final response = await request();
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Contraseña o PIN incorrecto. Intente nuevamente.');
      }
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('timeRemaining')) {
          throw UserNotVerifiedException(timeRemaining: data['timeRemaining']);
        }
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Recurso no encontrado (404)');
      }
      throw Exception(ErrorMapper.mapToUserMessage(e.response?.data));
    } catch (e) {
      throw Exception('Error inesperado: \$e');
    }
  }
}
