import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/auth/presentation/widgets/register_steps/verification_step.dart';
import 'package:flutter/material.dart';

/// UI-only verification. Reuses the existing OTP input and resend countdown;
/// no authentication event, message, or ownership change is triggered here.
class AnimalTransferVerificationScreen extends StatefulWidget {
  final String identifier;
  final VoidCallback onBack;
  final ValueChanged<String> onVerify;

  const AnimalTransferVerificationScreen({
    super.key,
    required this.identifier,
    required this.onBack,
    required this.onVerify,
  });

  @override
  State<AnimalTransferVerificationScreen> createState() =>
      _AnimalTransferVerificationScreenState();
}

class _AnimalTransferVerificationScreenState
    extends State<AnimalTransferVerificationScreen> {
  final _verificationKey = GlobalKey<VerificationStepState>();
  bool _isCodeComplete = false;
  bool _canResend = true;

  void _onCodeChanged() {
    setState(() {
      _isCodeComplete =
          _verificationKey.currentState?.isCodeComplete() ?? false;
    });
  }

  void _onTimerChanged() {
    setState(() {
      _canResend = _verificationKey.currentState?.canResend ?? true;
    });
  }

  void _resend() {
    if (!_canResend) return;
    final verification = _verificationKey.currentState;
    verification?.clearCode();
    verification?.restartTimer(180000);
    setState(() => _canResend = false);
  }

  @override
  Widget build(BuildContext context) {
    return ModalPageLayout(
      title: '',
      titleStyle: const TextStyle(fontSize: 0),
      trailingIcon: const SizedBox.shrink(),
      bottomSafeAreaColor: AppColors.white,
      headerChildren: [
        Positioned(
          top: 18,
          left: 16,
          child: IconButton(
            key: const Key('transfer-verification-back'),
            tooltip: 'Volver a confirmar usuario',
            onPressed: widget.onBack,
            color: AppColors.greyMedio,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          88,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerificationStep(
              key: _verificationKey,
              identifier: widget.identifier,
              autofocus: false,
              enableSmsAutofill: false,
              onResendCode: _resend,
              onCodeChanged: _onCodeChanged,
              onTimerChanged: _onTimerChanged,
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              key: const Key('transfer-verify-code'),
              text: 'Verificar',
              onPressed: _isCodeComplete
                  ? () => widget.onVerify(
                      _verificationKey.currentState!.getCode(),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Text('¿No recibiste un código?', style: AppTypography.body4),
                TextButton(
                  key: const Key('transfer-resend-code'),
                  onPressed: _canResend ? _resend : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryFrances,
                    disabledForegroundColor: AppColors.greyMedio,
                    textStyle: AppTypography.body3,
                  ),
                  child: Text(
                    _canResend
                        ? 'Reenviar'
                        : 'Reenviar (${_verificationKey.currentState?.formatTimeRemaining() ?? '03:00'})',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
