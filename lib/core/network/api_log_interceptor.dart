import 'http_log_redactor.dart';
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
URL: [${options.method}] ${HttpLogRedactor.target(options)}
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
URL: [${response.requestOptions.method}] ${HttpLogRedactor.target(response.requestOptions)}
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
URL: [${err.requestOptions.method}] ${HttpLogRedactor.target(err.requestOptions)}
Status: ${err.response?.statusCode}
Message: ${sensitive ? '[redacted]' : err.message}
Data: ${sensitive ? '[redacted]' : err.response?.data}
Type: ${err.type}
------------------
''');
    handler.next(err);
  }

  bool _isSensitive(RequestOptions options) =>
      HttpLogRedactor.isSensitive(options);
  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) =>
      HttpLogRedactor.headers(headers);
}
