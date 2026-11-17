import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiLogInterceptor extends Interceptor {
  final Logger _logger;

  ApiLogInterceptor({Logger? logger})
    : _logger =
          logger ??
          Logger(
            printer: PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 5,
              lineLength: 80,
              colors: true,
              printEmojis: true,
            ),
          );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sensitive = _isSensitive(options);
    _logger.d('''
--- HTTP REQUEST ---
URL: [${options.method}] ${sensitive ? options.path : options.uri}
Headers: ${_safeHeaders(options.headers)}
Payload: ${sensitive ? '[redacted]' : options.data}
--------------------
''');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sensitive = _isSensitive(response.requestOptions);
    _logger.i('''
--- HTTP RESPONSE ---
URL: [${response.requestOptions.method}] ${sensitive ? response.requestOptions.path : response.requestOptions.uri}
Status: ${response.statusCode} - ${response.statusMessage}
Data Type: ${response.data.runtimeType}
Data: ${sensitive ? '[redacted]' : response.data}
---------------------
''');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sensitive = _isSensitive(err.requestOptions);
    _logger.e('''
--- HTTP ERROR ---
URL: [${err.requestOptions.method}] ${sensitive ? err.requestOptions.path : err.requestOptions.uri}
Status: ${err.response?.statusCode}
Message: ${sensitive ? '[redacted]' : err.message}
Data: ${sensitive ? '[redacted]' : err.response?.data}
Type: ${err.type}
------------------
''');
    handler.next(err);
  }

  bool _isSensitive(RequestOptions options) =>
      options.extra['redactTransferPayload'] == true ||
      options.path.startsWith('/animal-transfers') ||
      options.path.startsWith('/animal-ownership-history') ||
      options.path.startsWith('/notifications') ||
      options.path.contains('/download-url');

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) => {
    for (final entry in headers.entries)
      entry.key:
          const {
            'authorization',
            'cookie',
            'idempotency-key',
          }.contains(entry.key.toLowerCase())
          ? '[redacted]'
          : entry.value,
  };
}
