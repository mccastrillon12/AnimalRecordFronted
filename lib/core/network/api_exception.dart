class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? data;
  final String? path;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.path,
  });

  @override
  String toString() => message;
}
