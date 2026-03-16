import 'package:animal_record/core/theme/app_spacing.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerificationStep extends StatefulWidget {
  final String identifier;
  final VoidCallback onResendCode;
  final VoidCallback? onCodeChanged;
  final VoidCallback? onTimerChanged;
  final bool isResending;
  final int? initialTimeRemaining;
  final bool hasError;
  final String? errorMessage;

  const VerificationStep({
    super.key,
    required this.identifier,
    required this.onResendCode,
    this.onCodeChanged,
    this.onTimerChanged,
    this.isResending = false,
    this.initialTimeRemaining,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<VerificationStep> createState() => VerificationStepState();
}

class VerificationStepState extends State<VerificationStep> with CodeAutoFill {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTimeRemaining != null) {
      _startTimer(widget.initialTimeRemaining!);
    }

    _focusNode.addListener(_onFocusChange);

    // Start listening for SMS if the identifier is a phone number
    if (!widget.identifier.contains('@')) {
      listenForCode();
    }
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 5) {
      setState(() {
        _controller.text = code!;
      });
      widget.onCodeChanged?.call();
    }
  }

  void _startTimer(int milliseconds) {
    setState(() {
      _remainingSeconds = (milliseconds / 1000).round();
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    if (!widget.identifier.contains('@')) {
      cancel(); // Cancel SmsAutoFill listener
    }
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String getCode() {
    return _controller.text;
  }

  bool isCodeComplete() {
    return getCode().length == 5;
  }

  void restartTimer(int milliseconds) {
    _timer?.cancel();
    _startTimer(milliseconds);
  }

  bool get canResend => _canResend;

  String formatTimeRemaining() => _formatTime(_remainingSeconds);

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.identifier.contains('@');
    final displayContact = widget.identifier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Verifica tu ${isEmail ? "correo" : "número celular"}',
          style: AppTypography.heading1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ingresa el código de verificación que\nhemos enviado a $displayContact',
          style: AppTypography.body4.copyWith(color: AppColors.greyNegro),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 80),
        Stack(
          alignment: Alignment.center,
          children: [
            // Visual Boxes
            GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
                _controller.selection =
                    TextSelection.collapsed(offset: _controller.text.length);
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isFocused = (_focusNode.hasFocus &&
                          _controller.text.length == index) ||
                      (_controller.text.length == 5 &&
                          index == 4 &&
                          _focusNode.hasFocus);

                  final isFilled = index < _controller.text.length;

                  String char = '';
                  if (isFilled) {
                    char = _controller.text[index];
                  }

                  return Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.error
                            : isFocused
                                ? AppColors.primaryAzulClaro
                                : AppColors.greyBordes,
                        width: isFocused || widget.hasError ? 2 : 1,
                      ),
                      borderRadius: index == 0
                          ? const BorderRadius.horizontal(
                              left: Radius.circular(8))
                          : index == 4
                              ? const BorderRadius.horizontal(
                                  right: Radius.circular(8))
                              : BorderRadius.zero,
                    ),
                    child: Text(
                      char.toUpperCase(),
                      style: AppTypography.heading2,
                    ),
                  );
                }),
              ),
            ),
            // Invisible TextField
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  maxLength: 5,
                  autofocus: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (value) {
                    setState(() {});
                    widget.onCodeChanged?.call();
                    if (value.length == 5) {
                      _focusNode.unfocus();
                    }
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.hasError && widget.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.m),
          Text(
            widget.errorMessage!,
            style: AppTypography.body5.copyWith(
              color: AppColors.error,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
