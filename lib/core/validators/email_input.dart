import 'package:formz/formz.dart';

enum EmailValidationError { invalid }

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) return null; // Allow empty initially or handle required elsewhere if needed
    return _emailRegExp.hasMatch(value) ? null : EmailValidationError.invalid;
  }
}
