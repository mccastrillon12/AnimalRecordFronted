import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import '../services/token_storage.dart';

/// Interceptor to automatically add auth tokens to requests and handle token refresh
class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;

  // Rate limiting for refresh attempts
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;
  DateTime? _lastRefreshAttempt;

  AuthInterceptor({required this.tokenStorage, required this.dio});

  // Logger instance for better logging
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
    // Skip adding token for auth endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    // Get access token and validate it's not expired
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
    // Handle 401 Unauthorized - token expired
    // Skip retry for change-password to avoid infinite loop if 401 is used for "Wrong Password"
    final path = err.requestOptions.path;
    _logger.e('AuthInterceptor Error: ${err.type} - ${err.message} at $path');
    if (err.response != null) {
      _logger.e('Response data: ${err.response?.data}');
    }

    if (err.response?.statusCode == 401 &&
        !_isAuthEndpoint(path) &&
        !path.contains('change-password')) {
      // Broadened check
      // Check rate limiting
      if (_isRefreshRateLimited()) {
        _logger.w('Refresh rate limit exceeded, clearing tokens');
        await tokenStorage.clearTokens();
        return handler.next(err);
      }

      try {
        // Try to refresh the token
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, clear tokens and let error propagate
        _logger.e('Token refresh failed', error: e);
        await tokenStorage.clearTokens();
      }
    }

    return handler.next(err);
  }

  /// Get access token and validate it's not expired
  Future<String?> _getValidAccessToken() async {
    try {
      final token = await tokenStorage.getAccessToken();

      if (token == null) return null;

      // Validate JWT is not expired
      if (JwtDecoder.isExpired(token)) {
        _logger.w('Access token expired, refreshing proactively');
        return await _refreshToken();
      }

      return token;
    } catch (e) {
      // If JWT parsing fails, token is invalid
      _logger.w('Invalid JWT token', error: e);
      return null;
    }
  }

  /// Check if refresh attempts are rate limited
  bool _isRefreshRateLimited() {
    final now = DateTime.now();

    // Reset counter if more than 5 minutes have passed
    if (_lastRefreshAttempt != null &&
        now.difference(_lastRefreshAttempt!).inMinutes > 5) {
      _refreshAttempts = 0;
      _lastRefreshAttempt = null;
    }

    // Check if max attempts exceeded
    if (_refreshAttempts >= _maxRefreshAttempts) {
      return true;
    }

    return false;
  }

  /// Check if path is an auth endpoint that shouldn't have token
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/verify') ||
        path.contains('/auth/social/') ||
        path.contains(
          '/users/identification/',
        ) || // Check if identification exists (public)
        (path.contains('/users') &&
            !path.contains('/')); // POST /users signup (public)
  }

  /// Refresh the access token using refresh token
  Future<String?> _refreshToken() async {
    try {
      // Update rate limiting counters
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

          // Some backends also return a new refresh token
          if (newRefreshToken != null) {
            await tokenStorage.saveRefreshToken(newRefreshToken);
          }

          // Reset counter on success
          _refreshAttempts = 0;
          _lastRefreshAttempt = null;

          _logger.i('Token refreshed successfully');
          return newAccessToken;
        }
      }

      return null;
    } on DioException catch (e) {
      // If refresh token is invalid (403) or expired (401), logout
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
