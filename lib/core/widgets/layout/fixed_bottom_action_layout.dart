import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class FixedBottomActionLayout extends StatelessWidget {
  /// The main scrollable content.
  /// Typically this should be a SingleChildScrollView or similar scrollable widget.
  final Widget child;

  /// The widget to be displayed at the bottom, fixed in place.
  /// This area will have standard padding applied.
  final Widget bottomChild;

  /// Optional padding for the bottom child. Defaults to AppSpacing.l (24.0).
  final EdgeInsetsGeometry? padding;

  const FixedBottomActionLayout({
    super.key,
    required this.child,
    required this.bottomChild,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ensure the child takes up available space
        Expanded(child: child),
        // Fixed bottom area with standard spacing
        Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.l),
          child: bottomChild,
        ),
        // Safe area spacing at the very bottom
        const SizedBox(height: 20),
      ],
    );
  }
}
