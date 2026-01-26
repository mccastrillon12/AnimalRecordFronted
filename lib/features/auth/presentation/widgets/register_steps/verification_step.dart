import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class VerificationStep extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final VoidCallback onResendCode;
  final VoidCallback? onCodeChanged;
  final VoidCallback? onTimerChanged;
  final bool isResending;
  final int? initialTimeRemaining;

  const VerificationStep({
    super.key,
    required this.email,
    this.phoneNumber,
    required this.onResendCode,
    this.onCodeChanged,
    this.onTimerChanged,
    this.isResending = false,
    this.initialTimeRemaining,
  });

  @override
  State<VerificationStep> createState() => VerificationStepState();
}

class VerificationStepState extends State<VerificationStep> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTimeRemaining != null) {
      _startTimer(widget.initialTimeRemaining!);
    }
  }

  void _startTimer(int milliseconds) {
    setState(() {
      _remainingSeconds = (milliseconds / 1000).round();
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _canResend = true;
        }
      });
      widget.onTimerChanged?.call();
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String getCode() {
    return _controllers.map((c) => c.text).join();
  }

  bool isCodeComplete() {
    return getCode().length == 5;
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    widget.onCodeChanged?.call();
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void restartTimer(int milliseconds) {
    _timer?.cancel();
    _startTimer(milliseconds);
  }

  bool get canResend => _canResend;

  String formatTimeRemaining() => _formatTime(_remainingSeconds);

  @override
  Widget build(BuildContext context) {
    final displayContact =
        widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
        ? widget.phoneNumber!
        : widget.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Verifica tu ${widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty ? "número celular" : "correo"}',
          style: AppTypography.heading1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Ingresa el código de verificación que\nhemos enviado a $displayContact',
          style: AppTypography.body4.copyWith(color: AppColors.greyNegro),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 80),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return _CodeInputField(
              index: index,
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              onChanged: (value) => _onCodeChanged(index, value),
              onBackspace: () => _onBackspace(index),
            );
          }),
        ),
      ],
    );
  }
}

class _CodeInputField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onBackspace;

  const _CodeInputField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(8);
    if (index == 0) {
      // First field: round left corners only
      return const BorderRadius.only(topLeft: radius, bottomLeft: radius);
    } else if (index == 4) {
      // Last field: round right corners only
      return const BorderRadius.only(topRight: radius, bottomRight: radius);
    } else {
      // Middle fields: no rounded corners
      return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.heading2,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: const BorderSide(color: AppColors.greyMedio, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: const BorderSide(
              color: AppColors.primaryAzulClaro,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.next,
        onTap: () {
          // Clear the field when tapped to allow re-entering
          controller.clear();
        },
        onChanged: (value) {
          onChanged(value);
          if (value.isEmpty) {
            // User pressed backspace
            onBackspace();
          }
        },
      ),
    );
  }
}
