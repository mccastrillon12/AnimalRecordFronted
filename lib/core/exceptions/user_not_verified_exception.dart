/// Exception thrown when a user attempts to login but has not verified their account.
///
/// Contains optional [timeRemaining] in milliseconds before the user can request
/// a new verification code.
class UserNotVerifiedException implements Exception {
  /// Time in milliseconds until the user can request a new verification code.
  /// Null if no time restriction applies.
  final int? timeRemaining;

  /// Creates a [UserNotVerifiedException] with optional [timeRemaining].
  UserNotVerifiedException({this.timeRemaining});

  @override
  String toString() {
    if (timeRemaining != null) {
      return 'UserNotVerifiedException: User not verified. Time remaining: ${timeRemaining}ms';
    }
    return 'UserNotVerifiedException: User not verified';
  }
}
