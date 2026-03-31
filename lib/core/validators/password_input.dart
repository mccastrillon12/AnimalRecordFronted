import 'package:formz/formz.dart';

enum PasswordValidationError { invalid }

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.invalid;
    
    final bool hasMinLength = value.length >= 8;
    final bool hasLower = value.contains(RegExp(r'[a-z]'));
    final bool hasUpper = value.contains(RegExp(r'[A-Z]'));
    final bool hasDigit = value.contains(RegExp(r'[0-9]'));
    final bool hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return (hasMinLength && hasLower && hasUpper && hasDigit && hasSpecial)
        ? null
        : PasswordValidationError.invalid;
  }
}
