import 'dart:convert';
import 'package:animal_record/core/network/api_log_interceptor.dart';
import 'package:animal_record/core/network/auth_interceptor.dart';
import 'package:animal_record/core/network/http_log_redactor.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/utils/animal_image_url.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _Tokens extends Mock implements TokenStorage {}

class _Dio extends Mock implements Dio {}

class _ErrorHandler extends ErrorInterceptorHandler {
  Future<dynamic> get completion => future;
}

class _Filter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _Output extends LogOutput {
  final lines = <String>[];
  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  setUpAll(() => registerFallbackValue(RequestOptions(path: '/')));
  late _Output output;
  late Logger logger;
  setUp(() {
    output = _Output();
    logger = Logger(
      filter: _Filter(),
      output: output,
      printer: SimplePrinter(colors: false),
    );
  });
  tearDown(() => logger.close());

  test(
    'la misma política oculta firmas, autorización, OTP y respuestas de autenticación',
    () async {
      final interceptor = ApiLogInterceptor(logger: logger);
      final options = RequestOptions(
        path: '/auth/refresh',
        method: 'POST',
        headers: {
          'Authorization': 'SENSITIVE_AUTH',
          'X-Proof': 'SENSITIVE_PROOF',
        },
        data: {'refreshToken': 'SENSITIVE_REFRESH'},
      );
      interceptor.onRequest(options, RequestInterceptorHandler());
      interceptor.onResponse(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'accessToken': 'SENSITIVE_ACCESS'},
        ),
        ResponseInterceptorHandler(),
      );
      final photo = RequestOptions(
        path: '/animal-transfers/id',
        queryParameters: {'X-Amz-Signature': 'SENSITIVE_SIGNATURE'},
      );
      final handler = _ErrorHandler();
      final handled = expectLater(handler.completion, throwsA(anything));
      interceptor.onError(
        DioException(
          requestOptions: photo,
          message: 'SENSITIVE_ERROR',
          response: Response(
            requestOptions: photo,
            statusCode: 403,
            data: {'otp': 'SENSITIVE_OTP'},
          ),
        ),
        handler,
      );
      await handled;
      expect(output.lines.join('\n'), isNot(contains('SENSITIVE_')));
      expect(output.lines.join('\n'), contains('403'));
      expect(
        HttpLogRedactor.target(
          RequestOptions(path: '/auth/reset/SENSITIVE_TOKEN'),
        ),
        '/auth/[redacted]',
      );
    },
  );

  test(
    'el interceptor conserva la autorización sin registrar el token ni el cuerpo del error',
    () async {
      final tokens = _Tokens();
      final token =
          'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.test-only';
      when(() => tokens.getAccessToken()).thenAnswer((_) async => token);
      final interceptor = AuthInterceptor(
        tokenStorage: tokens,
        dio: _Dio(),
        logger: logger,
      );
      final options = RequestOptions(path: '/animals');
      await interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers['Authorization'], 'Bearer $token');
      final handler = _ErrorHandler();
      final handled = expectLater(handler.completion, throwsA(anything));
      await interceptor.onError(
        DioException(
          requestOptions: options,
          message: 'SENSITIVE_MESSAGE',
          response: Response(
            requestOptions: options,
            statusCode: 403,
            data: {'proof': 'SENSITIVE_PROOF'},
          ),
        ),
        handler,
      );
      await handled;
      final logs = output.lines.join('\n');
      expect(logs, isNot(contains(token.substring(0, 20))));
      expect(logs, isNot(contains('SENSITIVE_')));
    },
  );

  test(
    'la renovación de sesión mantiene el token nuevo y el reintento HTTP',
    () async {
      final tokens = _Tokens();
      final dio = _Dio();
      when(
        () => tokens.getRefreshToken(),
      ).thenAnswer((_) async => 'SENSITIVE_REFRESH');
      when(() => tokens.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => tokens.saveRefreshToken(any())).thenAnswer((_) async {});
      when(
        () => dio.post<dynamic>('/auth/refresh', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 200,
          data: {
            'accessToken': 'SENSITIVE_NEW_ACCESS',
            'refreshToken': 'SENSITIVE_NEW_REFRESH',
          },
        ),
      );
      when(() => dio.fetch<dynamic>(any())).thenAnswer(
        (invocation) async => Response(
          requestOptions:
              invocation.positionalArguments.single as RequestOptions,
          statusCode: 200,
        ),
      );
      final interceptor = AuthInterceptor(
        tokenStorage: tokens,
        dio: dio,
        logger: logger,
      );
      final options = RequestOptions(path: '/animals');
      final handler = ErrorInterceptorHandler();
      await interceptor.onError(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
        ),
        handler,
      );
      expect(options.headers['Authorization'], 'Bearer SENSITIVE_NEW_ACCESS');
      verify(() => tokens.saveAccessToken('SENSITIVE_NEW_ACCESS')).called(1);
      verify(() => dio.fetch<dynamic>(options)).called(1);
      expect(output.lines.join('\n'), isNot(contains('SENSITIVE_')));
    },
  );

  test(
    'las URL de producción requieren HTTPS y conservan la firma completa',
    () {
      const signed =
          'https://example.com/photo?X-Amz-Signature=a%2Bb%2Fc&expires=10';
      expect(validAnimalImageUrl(signed, allowInsecureHttp: false), signed);
      expect(
        validAnimalImageUrl(
          'http://example.com/photo?Signature=secret',
          allowInsecureHttp: false,
        ),
        isNull,
      );
      expect(
        validAnimalImageUrl('http://localhost/photo', allowInsecureHttp: true),
        isNotNull,
      );
    },
  );
}
