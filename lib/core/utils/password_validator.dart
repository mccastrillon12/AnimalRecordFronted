/// Utilidad para validación de contraseñas
/// Consolida la lógica de validación de requisitos de contraseña
class PasswordValidator {
  /// Verifica que la contraseña tenga al menos 8 caracteres
  static bool hasMinLength(String password) => password.length >= 8;

  /// Verifica que la contraseña contenga mayúsculas y minúsculas
  static bool hasUpperAndLower(String password) =>
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[A-Z]'));

  /// Verifica que la contraseña contenga al menos un número
  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  /// Verifica que la contraseña contenga caracteres especiales
  static bool hasSpecialChar(String password) =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// Valida que la contraseña cumpla con todos los requisitos
  static bool isValid(String password) =>
      hasMinLength(password) &&
      hasUpperAndLower(password) &&
      hasNumber(password) &&
      hasSpecialChar(password);
}
