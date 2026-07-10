import '../errors/failure.dart';

/// Converts a caught exception into a [ServerFailure] with a clean message.
///
/// Strips the `Exception: ` prefix that Dart adds when calling `.toString()`
/// on an [Exception] object, so error messages shown in the UI are user-friendly.
Failure mapExceptionToFailure(Object e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  return ServerFailure(msg);
}
