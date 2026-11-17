class TransferOtpPolicy {
  static const int length = 5;

  static bool isValid(String code) =>
      code.length == length && RegExp(r'^[0-9]+$').hasMatch(code);
}
