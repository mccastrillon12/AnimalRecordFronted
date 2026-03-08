import 'package:flutter/services.dart';

class MixedEmailPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Determine if we should handle it as an email because it contains '@'
    if (newValue.text.contains('@') && !oldValue.text.contains('@')) {
      String text = newValue.text.replaceFirst(
        RegExp(r'^(\(\+57\)\s?|\+57\s?|\+\d*\s?)'),
        '',
      );
      int offsetDiff = newValue.text.length - text.length;
      int newOffset = newValue.selection.baseOffset - offsetDiff;
      if (newOffset < 0) newOffset = 0;

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }

    // If it's empty and user types a digit, add '+57 '
    if (oldValue.text.isEmpty && newValue.text.isNotEmpty) {
      if (RegExp(r'^[0-9]').hasMatch(newValue.text)) {
        final newText = '+57 ${newValue.text}';
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }

    // Deletion logic
    if (oldValue.text.length > newValue.text.length) {
      // If they delete the '+', we clear everything assuming they want to wipe the phone number
      if (!newValue.text.contains('+') && oldValue.text.contains('+')) {
        if (newValue.text.replaceAll(RegExp(r'[0-9 ]'), '').isEmpty) {
          return const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
        }
      }
      return newValue;
    }

    // If they are adding characters and it starts with '+'
    if (newValue.text.startsWith('+')) {
      bool hasNonPhoneChars = newValue.text
          .replaceAll(RegExp(r'[0-9\+ ]'), '')
          .isNotEmpty;

      if (hasNonPhoneChars) {
        // They typed a letter or symbol. Transitioning to email format.
        // Strip the phone prefix.
        String text = newValue.text.replaceFirst(
          RegExp(r'^(\(\+57\)\s?|\+57\s?|\+\d*\s?)'),
          '',
        );
        int offsetDiff = newValue.text.length - text.length;
        int newOffset = newValue.selection.baseOffset - offsetDiff;
        if (newOffset < 0) newOffset = 0;

        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      }
    }

    return newValue;
  }
}
