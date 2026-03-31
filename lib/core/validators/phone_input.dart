import 'package:formz/formz.dart';

enum PhoneValidationError { invalid }

class PhoneInput extends FormzInput<String, PhoneValidationError> {
  const PhoneInput.pure() : super.pure('');
  const PhoneInput.dirty([super.value = '']) : super.dirty();

  @override
  PhoneValidationError? validator(String value) {
    if (value.isEmpty) return null; // Let the bloc decide if it's required
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? null : PhoneValidationError.invalid;
  }
}
