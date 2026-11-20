import 'package:dio/dio.dart';

/// A single policy for every HTTP logger. Secrets never enter log arguments.
class HttpLogRedactor {
  static bool isSensitive(RequestOptions options) {
    final path = Uri.tryParse(options.path)?.path ?? options.path;
    return options.extra['redactTransferPayload'] == true ||
        const [
          '/auth',
          '/users',
          '/animals',
          '/medical-documents',
          '/animal-transfers',
          '/animal-ownership-history',
          '/notifications',
        ].any((prefix) => path == prefix || path.startsWith('$prefix/')) ||
        path.contains('/download-url') ||
        options.uri.queryParameters.keys.any((key) => _secretKey(key));
  }

  static String target(RequestOptions options) {
    final path = Uri.tryParse(options.path)?.path ?? '[invalid path]';
    if (path == '/auth' || path.startsWith('/auth/')) return '/auth/[redacted]';
    if (path == '/users' || path.startsWith('/users/')) {
      return '/users/[redacted]';
    }
    return isSensitive(options) ? path : options.uri.toString();
  }

  static Map<String, dynamic> headers(Map<String, dynamic> headers) => {
    for (final entry in headers.entries)
      entry.key: _secretKey(entry.key) ? '[redacted]' : entry.value,
  };

  static bool _secretKey(String key) {
    final lower = key.toLowerCase();
    return lower.startsWith('x-amz-') ||
        lower.startsWith('x-goog-') ||
        RegExp(
          r'authorization|cookie|token|proof|otp|password|secret|signature|credential|api[-_]?key|idempotency|publicationhash',
        ).hasMatch(lower);
  }
}
