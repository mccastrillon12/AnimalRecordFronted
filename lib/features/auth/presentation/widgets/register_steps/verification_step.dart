import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class VerificationStep extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final VoidCallback onResendCode;
  final int? initialTimeRemaining;

  const VerificationStep({
    super.key,
    required this.email,
    this.phoneNumber,
    required this.onResendCode,
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
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

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
          style: AppTypography.heading2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Ingresa el código de verificación que\nhemos enviado a $displayContact',
          style: AppTypography.body4.copyWith(color: AppColors.greyMedio),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
              child: _CodeInputField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                onChanged: (value) => _onCodeChanged(index, value),
                onBackspace: () => _onBackspace(index),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No recibiste un código?  ',
              style: AppTypography.body4.copyWith(color: AppColors.greyMedio),
            ),
            GestureDetector(
              onTap: _canResend ? widget.onResendCode : null,
              child: Text(
                _canResend
                    ? 'Reenviar'
                    : 'Reenviar (${_formatTime(_remainingSeconds)})',
                style: AppTypography.body4.copyWith(
                  color: _canResend
                      ? AppColors.primaryAzulClaro
                      : AppColors.greyMedio,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onBackspace;

  const _CodeInputField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
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
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.greyClaro, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.primaryAzulClaro,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
