import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/domain/services/transfer_otp_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Numeric OTP input for the transfer challenge.
class TransferOtpInput extends StatefulWidget {
  final String maskedDestination;
  final bool isPhone;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TransferOtpInput({
    super.key,
    required this.maskedDestination,
    required this.isPhone,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<TransferOtpInput> createState() => _TransferOtpInputState();
}

class _TransferOtpInputState extends State<TransferOtpInput> with CodeAutoFill {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
    if (widget.isPhone) {
      listenForCode(
        smsCodeRegexPattern: '\\b[0-9]{${TransferOtpPolicy.length}}\\b',
      );
    }
  }

  void _refresh() => setState(() {});

  @override
  void codeUpdated() {
    final receivedCode = code;
    if (!mounted ||
        receivedCode == null ||
        !TransferOtpPolicy.isValid(receivedCode)) {
      return;
    }
    widget.controller.value = TextEditingValue(
      text: receivedCode,
      selection: TextSelection.collapsed(offset: receivedCode.length),
    );
    widget.onChanged(receivedCode);
    _focusNode.unfocus();
    setState(() {});
  }

  @override
  void dispose() {
    if (widget.isPhone) cancel();
    _focusNode.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Column(
      children: [
        Text(
          'Verifica tu ${widget.isPhone ? 'número celular' : 'correo'}',
          style: AppTypography.heading1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ingresa el código de verificación que\nhemos enviado a ${widget.maskedDestination}',
          style: AppTypography.body4.copyWith(color: AppColors.greyNegro),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 80),
        Semantics(
          label: 'Código de transferencia de cinco dígitos',
          textField: true,
          child: Stack(
            children: [
              GestureDetector(
                onTap: _focusNode.requestFocus,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    TransferOtpPolicy.length,
                    (index) => Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _focusNode.hasFocus && index == code.length
                              ? AppColors.primaryAzulClaro
                              : AppColors.greyBordes,
                        ),
                        borderRadius: index == 0
                            ? const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              )
                            : index == TransferOtpPolicy.length - 1
                            ? const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              )
                            : BorderRadius.zero,
                      ),
                      child: Text(
                        index < code.length ? code[index] : '',
                        style: AppTypography.heading2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: TransferOtpPolicy.length,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputFormatter.withFunction(
                        (previous, next) =>
                            next.text.length > TransferOtpPolicy.length
                            ? previous
                            : next,
                      ),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      widget.onChanged(value);
                      if (TransferOtpPolicy.isValid(value)) {
                        _focusNode.unfocus();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
