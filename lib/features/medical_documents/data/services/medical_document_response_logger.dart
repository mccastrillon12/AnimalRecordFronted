import 'dart:convert';

import 'package:logger/logger.dart';

class MedicalDocumentResponseLogger {
  static const _chunkSize = 800;

  final Logger logger;

  const MedicalDocumentResponseLogger({required this.logger});

  void logResponse({
    required String operation,
    required int? statusCode,
    required Object? response,
  }) {
    assert(() {
      final serialized = _serialize(response);
      final chunkCount = serialized.isEmpty
          ? 1
          : (serialized.length / _chunkSize).ceil();
      logger.i(
        '[MedicalDocuments][$operation] Respuesta completa del backend '
        '(HTTP ${statusCode ?? '-'}) - $chunkCount fragmento(s)',
      );
      if (serialized.isEmpty) {
        logger.i('[MedicalDocuments][$operation][1/1] <respuesta vacía>');
        return true;
      }
      for (var index = 0; index < chunkCount; index++) {
        final start = index * _chunkSize;
        final end = (start + _chunkSize).clamp(0, serialized.length);
        logger.i(
          '[MedicalDocuments][$operation][${index + 1}/$chunkCount]\n'
          '${serialized.substring(start, end)}',
        );
      }
      return true;
    }());
  }

  String _serialize(Object? response) {
    try {
      return const JsonEncoder.withIndent('  ').convert(response);
    } on Object {
      return response?.toString() ?? '';
    }
  }
}
