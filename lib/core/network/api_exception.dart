class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? data;
  final String? path;
  final String? retryAfter;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.path,
    this.retryAfter,
  });

  @override
  String toString() => message;
}
