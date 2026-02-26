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
    _logger.d('''
--- HTTP REQUEST ---
URL: [${options.method}] ${options.uri}
Headers: ${options.headers}
Payload: ${options.data}
--------------------
''');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('''
--- HTTP RESPONSE ---
URL: [${response.requestOptions.method}] ${response.requestOptions.uri}
Status: ${response.statusCode} - ${response.statusMessage}
Data Type: ${response.data.runtimeType}
Data: ${response.data}
---------------------
''');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('''
--- HTTP ERROR ---
URL: [${err.requestOptions.method}] ${err.requestOptions.uri}
Status: ${err.response?.statusCode}
Message: ${err.message}
Data: ${err.response?.data}
Type: ${err.type}
------------------
''');
    handler.next(err);
  }
}
