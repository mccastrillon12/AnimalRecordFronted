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

    for (int i = 0; i < 5; i++) {
      _focusNodes[i].onKeyEvent = (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[i].text.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
            _controllers[i - 1].clear();
            widget.onCodeChanged?.call();
            setState(() {});
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }

    // Start listening for SMS if the identifier is a phone number
    if (!widget.identifier.contains('@')) {
      listenForCode();
    }
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 5) {
      setState(() {
        for (int i = 0; i < 5; i++) {
          _controllers[i].text = code![i];
        }
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
    if (value.length > 1) {
      // Handle pasting or autofill of multiple characters
      final code = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      for (int i = 0; i < code.length && (index + i) < 5; i++) {
        _controllers[index + i].text = code[i];
      }

      // Move focus to the last filled field or the next one
      int nextIndex = index + code.length;
      if (nextIndex > 4) nextIndex = 4;
      _focusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty && index < 4) {
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return _CodeInputField(
              index: index,
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              onChanged: (value) => _onCodeChanged(index, value),
              onBackspace: () => _onBackspace(index),
              hasError: widget.hasError,
            );
          }),
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

class _CodeInputField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onBackspace;
  final bool hasError;

  const _CodeInputField({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    this.hasError = false,
  });

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(8);
    if (index == 0) {
      return const BorderRadius.only(topLeft: radius, bottomLeft: radius);
    } else if (index == 4) {
      return const BorderRadius.only(topRight: radius, bottomRight: radius);
    } else {
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
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        // Removed maxLength: 1 to allow iOS to "type" or "paste" the full code.
        // We handle the length and distribution in _onCodeChanged.
        style: AppTypography.heading2,
        contextMenuBuilder: (context, editableTextState) {
          // Standard context menu for pasting
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: editableTextState.contextMenuButtonItems,
          );
        },
        obscureText: false,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.oneTimeCode],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.greyBordes,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _getBorderRadius(),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primaryAzulClaro,
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        textInputAction: TextInputAction.next,
        onTap: () {
          // Allow tapping to act fluidly for overwriting,
          // but if we want them to clear on tap, we can keep it.
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        },
        onChanged: (value) {
          onChanged(value);
        },
      ),
    );
  }
}
