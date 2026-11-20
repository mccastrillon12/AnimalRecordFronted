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

  /// Original server diagnostics for deliberate inspection, never automatic logs.
  String? get backendMessage {
    final payload = data;
    if (payload is! Map) return null;
    final message = payload['message'];
    if (message is String) return message;
    if (message is List && message.every((value) => value is String)) {
      return message.join('; ');
    }
    return null;
  }

  String? get timestamp {
    final payload = data;
    return payload is Map && payload['timestamp'] is String
        ? payload['timestamp'] as String
        : null;
  }

  /// Supports both delta-seconds and an HTTP-date in Retry-After.
  DateTime? get retryAfterDeadline {
    final value = retryAfter?.trim();
    if (value == null) return null;
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return seconds < 0
          ? null
          : DateTime.now().add(Duration(seconds: seconds));
    }
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final date = RegExp(
      r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(value);
    if (date == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months.indexOf(date[2]!);
    if (month < 0) return null;
    return DateTime.utc(
      int.parse(date[3]!),
      month + 1,
      int.parse(date[1]!),
      int.parse(date[4]!),
      int.parse(date[5]!),
      int.parse(date[6]!),
    );
  }

  @override
  String toString() => message;
}
