class PinValidator {
  static const int pinLength = 4;

  static bool isValid(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  static bool hasCorrectLength(String pin) => pin.length == pinLength;
}
