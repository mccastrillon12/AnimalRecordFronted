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

    // Allow digits, dashes, spaces, and email characters
    // No auto-prepending of dial codes here anymore as UI will handle the prefixIcon.
    final bool isPotentiallyEmail = newValue.text.contains('@') || 
                                    newValue.text.contains(RegExp(r'[a-zA-Z]'));

    if (!isPotentiallyEmail) {
      // If it looks like a phone number, limit to digits, dashes, spaces, parentheses and +
      final String filteredText = newValue.text.replaceAll(RegExp(r'[^0-9\-\s\(\)\+]'), '');
      if (filteredText != newValue.text) {
        int newOffset = newValue.selection.baseOffset - (newValue.text.length - filteredText.length);
        if (newOffset < 0) newOffset = 0;
        return TextEditingValue(
          text: filteredText,
          selection: TextSelection.collapsed(offset: newOffset),
        );
      }
    }

    return newValue;
  }
}
