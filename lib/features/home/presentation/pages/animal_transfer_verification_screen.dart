import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/services/transfer_otp_policy.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_otp_input.dart';
import 'package:flutter/material.dart';

class AnimalTransferVerificationScreen extends StatefulWidget {
  final TransferChallenge challenge;
  final VoidCallback onBack;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  final bool isLoading;
  final String? error;
  final bool canRetryCreation;
  final VoidCallback onRetryCreation;
  final VoidCallback onRenewAuthorization;
  final DateTime? authorizationExpiresAt;
  final bool canRenewAuthorization;
  final bool canBack;
  final VoidCallback onInspectRequests;

  const AnimalTransferVerificationScreen({
    super.key,
    required this.challenge,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
    required this.isLoading,
    required this.error,
    required this.canRetryCreation,
    required this.onRetryCreation,
    required this.onRenewAuthorization,
    required this.authorizationExpiresAt,
    required this.canRenewAuthorization,
    required this.canBack,
    required this.onInspectRequests,
  });

  @override
  State<AnimalTransferVerificationScreen> createState() =>
      _AnimalTransferVerificationScreenState();
}

class _AnimalTransferVerificationScreenState
    extends State<AnimalTransferVerificationScreen> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AnimalTransferVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge != widget.challenge) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Duration get _resendWait {
    final remaining = widget.challenge.resendAvailableAt.difference(
      DateTime.now(),
    );
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get _codeWait {
    final remaining = widget.challenge.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatWait(Duration duration) {
    final seconds = duration.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String get _timeLabel {
    return _formatWait(_resendWait);
  }

  bool get _authorizationExpired {
    final expiresAt = widget.authorizationExpiresAt;
    return expiresAt != null && !DateTime.now().isBefore(expiresAt);
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
            onPressed: widget.isLoading || !widget.canBack
                ? null
                : widget.onBack,
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
            TransferOtpInput(
              key: ValueKey(widget.challenge),
              maskedDestination: widget.challenge.maskedDestination,
              isPhone: widget.challenge.channel == 'PHONE',
              controller: _controller,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              _codeWait == Duration.zero
                  ? 'El código venció. Solicita uno nuevo.'
                  : 'El código vence en ${_formatWait(_codeWait)}',
              textAlign: TextAlign.center,
              style: AppTypography.body4,
            ),
            if (widget.error != null) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                widget.error!,
                style: AppTypography.body4.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              key: const Key('transfer-verify-code'),
              text: 'Verificar',
              isLoading: widget.isLoading,
              onPressed:
                  TransferOtpPolicy.isValid(_controller.text) &&
                      _codeWait != Duration.zero &&
                      !widget.isLoading &&
                      !widget.canRetryCreation
                  ? () => widget.onVerify(_controller.text)
                  : null,
            ),
            if (widget.canRetryCreation) ...[
              const SizedBox(height: AppSpacing.m),
              CustomButton(
                key: const Key('transfer-retry-create'),
                text: 'Reintentar la misma solicitud',
                isLoading: widget.isLoading,
                onPressed: widget.isLoading ? null : widget.onRetryCreation,
              ),
              if (widget.canRenewAuthorization && !_authorizationExpired)
                TextButton(
                  onPressed: widget.isLoading
                      ? null
                      : widget.onRenewAuthorization,
                  child: const Text('Solicitar nuevo código'),
                ),
              TextButton(
                onPressed: widget.onInspectRequests,
                child: const Text('Consultar solicitudes enviadas'),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Text('¿No recibiste un código?', style: AppTypography.body4),
                TextButton(
                  key: const Key('transfer-resend-code'),
                  onPressed:
                      _resendWait == Duration.zero &&
                          !widget.isLoading &&
                          !widget.canRetryCreation
                      ? widget.onResend
                      : null,
                  child: Text(
                    _resendWait == Duration.zero
                        ? 'Reenviar'
                        : 'Reenviar ($_timeLabel)',
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
