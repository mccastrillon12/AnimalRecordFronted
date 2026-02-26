import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import '../services/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;

  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;
  DateTime? _lastRefreshAttempt;

  AuthInterceptor({required this.tokenStorage, required this.dio});

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final accessToken = await _getValidAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    _logger.e('AuthInterceptor Error: ${err.type} - ${err.message} at $path');
    if (err.response != null) {
      _logger.e('Response data: ${err.response?.data}');
    }

    if (err.response?.statusCode == 401 &&
        !_isAuthEndpoint(path) &&
        !path.contains('change-password') &&
        !path.contains('/auth/pin')) {
      if (_isRefreshRateLimited()) {
        _logger.w('Refresh rate limit exceeded, clearing tokens');
        await tokenStorage.clearTokens();
        return handler.next(err);
      }

      try {
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        _logger.e('Token refresh failed', error: e);
        await tokenStorage.clearTokens();
      }
    }

    return handler.next(err);
  }

  Future<String?> _getValidAccessToken() async {
    try {
      final token = await tokenStorage.getAccessToken();
      _logger.d('🔑 Getting access token: ${token?.substring(0, 20)}...');

      if (token == null) {
        _logger.w('❌ No access token found in storage');
        return null;
      }

      if (JwtDecoder.isExpired(token)) {
        _logger.w('⏰ Access token expired, refreshing proactively');
        return await _refreshToken();
      }

      _logger.d('✅ Access token valid');
      return token;
    } catch (e) {
      _logger.w('⚠️ Invalid JWT token', error: e);
      return null;
    }
  }

  bool _isRefreshRateLimited() {
    final now = DateTime.now();

    if (_lastRefreshAttempt != null &&
        now.difference(_lastRefreshAttempt!).inMinutes > 5) {
      _refreshAttempts = 0;
      _lastRefreshAttempt = null;
    }

    if (_refreshAttempts >= _maxRefreshAttempts) {
      return true;
    }

    return false;
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/verify') ||
        path.contains('/auth/social/') ||
        path.contains('/users/identification/') ||
        path.endsWith('/users') ||
        path.contains('/locations/countries');
  }

  Future<String?> _refreshToken() async {
    try {
      _refreshAttempts++;
      _lastRefreshAttempt = DateTime.now();

      final refreshToken = await tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        return null;
      }

      _logger.i(
        'Refreshing access token (attempt $_refreshAttempts/$_maxRefreshAttempts)',
      );

      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await tokenStorage.saveAccessToken(newAccessToken);

          if (newRefreshToken != null) {
            await tokenStorage.saveRefreshToken(newRefreshToken);
          }

          _refreshAttempts = 0;
          _lastRefreshAttempt = null;

          _logger.i('Token refreshed successfully');
          return newAccessToken;
        }
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        _logger.w(
          'Refresh token invalid or expired (403/401), clearing session',
        );
        await tokenStorage.clearTokens();
        return null;
      }

      _logger.e('Refresh token error (DioException)', error: e);
      return null;
    } catch (e) {
      _logger.e('Refresh token error', error: e);
      return null;
    }
  }
}
