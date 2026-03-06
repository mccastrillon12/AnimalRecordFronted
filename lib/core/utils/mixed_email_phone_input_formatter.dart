import 'package:flutter/services.dart';

class MixedEmailPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.isEmpty && newValue.text.isNotEmpty) {
      if (RegExp(r'^[0-9]').hasMatch(newValue.text)) {
        final newText = '(+57) ${newValue.text}';
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
      return newValue;
    }

    final bool wasPhone = oldValue.text.startsWith('(+');

    if (wasPhone) {
      if (newValue.text.isEmpty) return newValue;

      int digitsCount = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (digitsCount == 0 ||
          (newValue.text.length < 5 && newValue.text.startsWith('(+'))) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }

      int diff = oldValue.text.length - newValue.text.length;
      if (diff == 1 && newValue.selection.isCollapsed) {
        int deletedIndex = newValue.selection.baseOffset;
        String deletedChar = oldValue.text[deletedIndex];

        if (deletedChar == ' ' ||
            deletedChar == ')' ||
            deletedChar == '+' ||
            deletedChar == '(') {
          int targetDeleteIndex = deletedIndex - 1;
          while (targetDeleteIndex >= 0 &&
              !RegExp(r'[0-9]').hasMatch(oldValue.text[targetDeleteIndex])) {
            targetDeleteIndex--;
          }

          if (targetDeleteIndex >= 0) {
            String newText =
                oldValue.text.substring(0, targetDeleteIndex) +
                oldValue.text.substring(targetDeleteIndex + 1);
            if (newText.replaceAll(RegExp(r'[^0-9]'), '').isEmpty ||
                newText == '(+57) ') {
              return const TextEditingValue(
                text: '',
                selection: TextSelection.collapsed(offset: 0),
              );
            }
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: targetDeleteIndex),
            );
          } else {
            return oldValue;
          }
        }
      }

      if (!newValue.text.startsWith('(+') || !newValue.text.contains(')')) {
        return oldValue;
      }

      if (newValue.text.replaceAll(RegExp(r'[0-9\+\(\) ]'), '').isNotEmpty) {
        return oldValue;
      }

      return newValue;
    }

    return newValue;
  }
}
