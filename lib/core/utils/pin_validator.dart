/// Utilidad para validación de PINs
class PinValidator {
  /// Longitud esperada del PIN
  static const int pinLength = 4;

  /// Verifica que el PIN tenga exactamente 4 dígitos
  static bool isValid(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  /// Verifica que el PIN tenga la longitud correcta
  static bool hasCorrectLength(String pin) => pin.length == pinLength;
}
