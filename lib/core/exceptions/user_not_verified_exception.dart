class UserNotVerifiedException implements Exception {
  final int? timeRemaining;

  UserNotVerifiedException({this.timeRemaining});

  @override
  String toString() {
    if (timeRemaining != null) {
      return 'UserNotVerifiedException: User not verified. Time remaining: ${timeRemaining}ms';
    }
    return 'UserNotVerifiedException: User not verified';
  }
}
