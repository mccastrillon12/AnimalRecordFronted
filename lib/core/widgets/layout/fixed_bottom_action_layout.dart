import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class FixedBottomActionLayout extends StatelessWidget {
  final Widget child;

  final Widget bottomChild;

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
        Expanded(child: child),

        Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.l),
          child: bottomChild,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
