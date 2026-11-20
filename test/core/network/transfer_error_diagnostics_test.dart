import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/network/transfer_error_diagnostics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const secret = 'PRIVATE_DIAGNOSTIC_VALUE';
  late DebugPrintCallback originalPrint;
  late List<String> logs;

  setUp(() {
    logs = [];
    originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
  });
  tearDown(() => debugPrint = originalPrint);

  test(
    'OTP diagnostics omit free text, unknown keys, nested secrets and signed URLs',
    () {
      final payload = {
        'message': 'Bearer $secret',
        secret: 'a secret in a field name',
        'unknownCredential': secret,
        'details': [
          {
            'url': 'https://example.com/file?X-Amz-Signature=$secret',
            'otp': 98765,
          },
          'proof=$secret',
        ],
      };
      TransferErrorDiagnostics.recordOtpChallengeFailure(
        ApiException(
          message: secret,
          statusCode: 429,
          path: '/animal-transfers/otp-challenges',
          data: payload,
        ),
      );
      final output = logs.join('\n');
      expect(output, isNot(contains(secret)));
      expect(output, isNot(contains('98765')));
      expect(output, isNot(contains('example.com')));
      expect(output, contains('"statusCode": 429'));
      expect(output, contains('[Transfers][OTP response] BEGIN'));
      expect(payload['unknownCredential'], secret);
    },
  );

  test('unstructured responses and byte payloads never enter the log', () {
    for (final payload in <Object?>[
      secret,
      [secret],
      [98, 97, 100],
      98765,
      null,
    ]) {
      TransferErrorDiagnostics.recordOtpChallengeFailure(
        ApiException(
          message: secret,
          statusCode: 503,
          path: '/animal-transfers/otp-challenges',
          data: payload,
        ),
      );
    }
    final output = logs.join('\n');
    expect(output, isNot(contains(secret)));
    expect(output, isNot(contains('98765')));
    expect(output, isNot(contains('98, 97, 100')));
    expect(output, contains('"statusCode": 503'));
  });

  test(
    'decision and detail diagnostics redact IDs while preserving status and labels',
    () {
      TransferErrorDiagnostics.recordDecisionFailure(
        const ApiException(
          message: secret,
          statusCode: 409,
          path: '/animal-transfers/PRIVATE_DIAGNOSTIC_VALUE/decisions',
          data: {'message': secret},
        ),
        transferId: secret,
      );
      TransferErrorDiagnostics.recordDetailFailure(
        const ApiException(
          message: secret,
          statusCode: 404,
          path: '/animal-transfers/PRIVATE_DIAGNOSTIC_VALUE',
          data: secret,
        ),
        transferId: secret,
      );
      final output = logs.join('\n');
      expect(output, isNot(contains(secret)));
      expect(output, contains('[Transfers][Decision response] BEGIN'));
      expect(output, contains('[Transfers][Detail response] BEGIN'));
      expect(output, contains('"statusCode": 409'));
      expect(output, contains('"statusCode": 404'));
    },
  );

  test(
    'fallback diagnostics and invalid status codes do not print raw values',
    () {
      TransferErrorDiagnostics.recordOtpChallengeFailure(StateError(secret));
      TransferErrorDiagnostics.recordOtpChallengeFailure(
        const ApiException(
          message: secret,
          statusCode: 98765,
          path: '/animal-transfers/otp-challenges',
          data: secret,
        ),
      );
      final output = logs.join('\n');
      expect(output, isNot(contains(secret)));
      expect(output, isNot(contains('98765')));
    },
  );
}
