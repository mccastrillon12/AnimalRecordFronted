import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/feedback/custom_snackbar.dart';

class ErrorDisplay {
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  static OverlayEntry? _secondaryEntry;
  static Timer? _secondaryTimer;

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (message.contains('¡Cuenta creada con éxito!')) {
      showSuccess(context, message, duration: duration);
      return;
    }

    _showTopOverlay(
      context: context,
      message: message,
      isError: true,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showTopOverlay(
      context: context,
      message: message,
      isError: false,
      duration: duration,
    );
  }

  static void _showTopOverlay({
    required BuildContext context,
    required String message,
    required bool isError,
    required Duration duration,
  }) {
    _removeCurrentOverlay();

    final overlayState = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 90.0,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSlideDown(
            child: CustomSnackBar(
              message: message,
              isError: isError,
              onClose: _removeCurrentOverlay,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_currentEntry!);

    _currentTimer = Timer(duration, () {
      _removeCurrentOverlay();
    });
  }

  static void _removeCurrentOverlay() {
    _currentTimer?.cancel();
    _currentTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void showSecondSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSecondaryOverlay(
      context: context,
      message: message,
      isError: false,
      duration: duration,
    );
  }

  static void _showSecondaryOverlay({
    required BuildContext context,
    required String message,
    required bool isError,
    required Duration duration,
  }) {
    _removeSecondaryOverlay();

    final overlayState = Overlay.of(context);

    _secondaryEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 170.0,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSlideDown(
            child: CustomSnackBar(
              message: message,
              isError: isError,
              onClose: _removeSecondaryOverlay,
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_secondaryEntry!);

    _secondaryTimer = Timer(duration, () {
      _removeSecondaryOverlay();
    });
  }

  static void _removeSecondaryOverlay() {
    _secondaryTimer?.cancel();
    _secondaryTimer = null;
    _secondaryEntry?.remove();
    _secondaryEntry = null;
  }
}

class _AnimatedSlideDown extends StatefulWidget {
  final Widget child;

  const _AnimatedSlideDown({required this.child});

  @override
  State<_AnimatedSlideDown> createState() => _AnimatedSlideDownState();
}

class _AnimatedSlideDownState extends State<_AnimatedSlideDown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}
