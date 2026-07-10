import 'package:flutter/material.dart';

class KeyboardSpacer extends StatelessWidget {
  final double keyboardVisibleHeight;
  final double keyboardHiddenHeight;

  const KeyboardSpacer({
    super.key,
    this.keyboardVisibleHeight = 20.0,
    this.keyboardHiddenHeight = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SizedBox(
      height: isKeyboardVisible
          ? keyboardVisibleHeight
          : keyboardHiddenHeight,
    );
  }
}
