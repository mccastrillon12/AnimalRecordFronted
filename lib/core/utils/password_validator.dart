class PasswordValidator {
  static bool hasMinLength(String password) => password.length >= 8;

  static bool hasUpperAndLower(String password) =>
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[A-Z]'));

  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  static bool hasSpecialChar(String password) =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  static bool isValid(String password) =>
      hasMinLength(password) &&
      hasUpperAndLower(password) &&
      hasNumber(password) &&
      hasSpecialChar(password);
}
