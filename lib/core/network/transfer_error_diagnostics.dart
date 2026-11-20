import 'dart:convert';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:flutter/foundation.dart';

/// Debug diagnostics contain only local labels and safe response metadata.
abstract final class TransferErrorDiagnostics {
  /// Explicit debug diagnostic for the OTP request triggered by the user.
  /// Never includes server text, arbitrary field names or credential values.
  static void recordOtpChallengeFailure(Object error) {
    _recordResponseFailure(
      error,
      method: 'POST',
      path: '/animal-transfers/otp-challenges',
      label: 'OTP response',
    );
  }

  static void recordDecisionFailure(
    Object error, {
    required String transferId,
  }) {
    _recordResponseFailure(
      error,
      method: 'POST',
      path: '/animal-transfers/${Uri.encodeComponent(transferId)}/decisions',
      label: 'Decision response',
    );
  }

  static void recordDetailFailure(Object error, {required String transferId}) {
    _recordResponseFailure(
      error,
      method: 'GET',
      path: '/animal-transfers/${Uri.encodeComponent(transferId)}',
      label: 'Detail response',
    );
  }

  static void _recordResponseFailure(
    Object error, {
    required String method,
    required String path,
    required String label,
  }) {
    assert(() {
      if (error is! ApiException ||
          Uri.tryParse(error.path ?? '')?.path != path) {
        record(error);
        return true;
      }
      final String responseBody;
      try {
        responseBody = const JsonEncoder.withIndent('  ').convert({
          'method': method,
          'path': label == 'OTP response'
              ? '/animal-transfers/otp-challenges'
              : label == 'Decision response'
              ? '/animal-transfers/[redacted]/decisions'
              : '/animal-transfers/[redacted]',
          'statusCode':
              error.statusCode != null &&
                  error.statusCode! >= 100 &&
                  error.statusCode! <= 599
              ? error.statusCode
              : null,
          'hasHttpResponse': error.statusCode != null,
          'body': _safeResponseSummary(error.data),
        });
      } on Object {
        // Diagnostic serialization must never replace the original failure.
        record(error);
        return true;
      }
      debugPrint(
        '[Transfers][$label] BEGIN\n$responseBody\n'
        '[Transfers][$label] END',
        wrapWidth: 900,
      );
      return true;
    }());
  }

  // Untrusted keys and values may themselves contain secrets. Summarize the
  // structure instead of trying to recognize every possible credential name.
  static Map<String, Object> _safeResponseSummary(Object? value) =>
      switch (value) {
        Map() => {
          'type': 'object',
          'fieldCount': value.length,
          'content': '[redacted]',
        },
        List() => {
          'type': 'list',
          'itemCount': value.length,
          'content': '[redacted]',
        },
        null => {'type': 'empty'},
        _ => {'type': 'scalar', 'content': '[redacted]'},
      };

  static void record(Object error) {
    assert(() {
      final status = error is ApiException ? error.statusCode : null;
      final statusLabel = status != null && status >= 100 && status <= 599
          ? '$status'
          : 'unavailable';
      final category = switch (error) {
        ApiException() => 'http',
        FormatException() => 'invalid_response',
        StateError() => 'invalid_state',
        _ => 'unexpected',
      };
      debugPrint(
        '[Transfers] category=$category status=$statusLabel '
        'operation=${_operation(error)} details=[redacted]',
      );
      return true;
    }());
  }

  static String _operation(Object error) {
    if (error is! ApiException) return 'unavailable';
    final path = Uri.tryParse(error.path ?? '')?.path ?? '';
    if (path.startsWith('/animal-transfers/otp-challenges')) return 'otp';
    if (path == '/animal-transfers/recipients') return 'recipient_search';
    if (path.startsWith('/animal-transfers')) return 'transfer';
    if (path.startsWith('/animal-ownership-history')) {
      return 'ownership_history';
    }
    if (path == '/catalogs/animal-transfer-reasons') return 'transfer_reasons';
    if (path == '/catalogs/animal-transfer-rejection-reasons') {
      return 'rejection_reasons';
    }
    if (path.startsWith('/notifications')) return 'notifications';
    return 'unavailable';
  }
}
