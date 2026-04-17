import 'package:formz/formz.dart';

enum TextInputError { empty }

class TextInput extends FormzInput<String, TextInputError> {
  const TextInput.pure() : super.pure('');
  const TextInput.dirty([super.value = '']) : super.dirty();

  @override
  TextInputError? validator(String value) {
    return value.trim().isNotEmpty ? null : TextInputError.empty;
  }
}
