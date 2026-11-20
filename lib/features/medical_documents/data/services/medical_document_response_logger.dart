import 'package:logger/logger.dart';

class MedicalDocumentResponseLogger {
  final Logger logger;

  const MedicalDocumentResponseLogger({required this.logger});

  void logResponse({
    required String operation,
    required int? statusCode,
    required Object? response,
  }) {
    assert(() {
      logger.i(
        '[MedicalDocuments][$operation] HTTP ${statusCode ?? '-'} '
        'type=${response.runtimeType} payload=[redacted]',
      );
      return true;
    }());
  }
}
