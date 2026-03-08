class ValidationUtils {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidEmail(text)) {
      return 'Introduzca una dirección de correo electrónico válida';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidPhone(text)) {
      return 'Introduzca su número de celular en el formato XXX-XXX-XX-XX';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    if (RegExp(r'^[0-9+\-\s()]+$').hasMatch(text)) {
      if (!isValidPhone(text)) {
        return 'Introduzca su número de celular en el formato XXX-XXX-XX-XX';
      }
    } else {
      if (!isValidEmail(text)) {
        return 'Introduzca una dirección de correo electrónico válida';
      }
    }
    return null;
  }
}
