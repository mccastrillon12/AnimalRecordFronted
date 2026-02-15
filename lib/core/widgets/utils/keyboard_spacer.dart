import 'package:flutter/material.dart';

/// A widget that creates a space equal to the bottom view insets (typically the keyboard height).
///
/// This widget is optimized to isolate the [MediaQuery] dependency.
/// Using this instead of calling [MediaQuery.of(context)] in a parent widget's build method
/// prevents the entire parent from rebuilding on every frame of the keyboard animation.
class KeyboardSpacer extends StatelessWidget {
  const KeyboardSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.of(context).viewInsets.bottom);
  }
}
