import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/domain/entities/verify_code_params.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../widgets/register_steps/verification_step.dart';
import '../widgets/auth_form_container.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final int? timeRemaining;

  const VerificationScreen({
    super.key,
    required this.email,
    this.phoneNumber,
    this.timeRemaining,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final GlobalKey<VerificationStepState> _verificationKey = GlobalKey();
  bool _isCodeComplete = false;
  bool _isResending = false;
  bool _canResendLocally = true;

  @override
  void initState() {
    super.initState();
    // If there's initialTimeRemaining, resend should be disabled initially
    _canResendLocally = widget.timeRemaining == null;
  }

  void _onCodeChanged() {
    setState(() {
      _isCodeComplete =
          _verificationKey.currentState?.isCodeComplete() ?? false;
    });
  }

  void _onTimerChanged() {
    setState(() {
      // Update local state from VerificationStepState
      _canResendLocally = _verificationKey.currentState?.canResend ?? true;
    });
  }

  void _verifyCode() {
    final code = _verificationKey.currentState?.getCode() ?? '';

    // Validate length
    if (code.length != 5) {
      ErrorDisplay.showError(
        context,
        'Por favor ingresa el código completo de 5 dígitos',
      );
      return;
    }

    // Validate numeric
    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
      ErrorDisplay.showError(context, 'El código debe contener solo números');
      return;
    }

    context.read<AuthBloc>().add(
      VerifyCodeSubmitted(VerifyCodeParams(email: widget.email, code: code)),
    );
  }

  void _resendVerificationCode() {
    // Get identifier (email or phone)
    final identifier =
        widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
        ? widget.phoneNumber!
        : widget.email;

    setState(() {
      _isResending = true;
    });

    context.read<AuthBloc>().add(ResendCodeSubmitted(identifier));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: true,
      showCancelButton: false,
      onBack: () => Navigator.pop(context),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is VerificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Verificación exitosa!')),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else if (state is ResendCodeSuccess) {
            // First restart timer to ensure VerificationStep state is updated
            _verificationKey.currentState?.restartTimer(180000);

            setState(() {
              _isResending = false;
              _canResendLocally = false; // Prevent flashing enabled state
            });
          } else if (state is AuthError) {
            setState(() {
              _isResending = false;
            });
            ErrorDisplay.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              VerificationStep(
                key: _verificationKey,
                email: widget.email,
                phoneNumber: widget.phoneNumber,
                onResendCode: _resendVerificationCode,
                initialTimeRemaining: widget.timeRemaining,
                onCodeChanged: _onCodeChanged,
                onTimerChanged: _onTimerChanged,
                isResending: _isResending,
              ),
              const SizedBox(height: AppSpacing.xxl),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return CustomButton(
                    text: 'Verificar',
                    isLoading: isLoading,
                    onPressed: _isCodeComplete && !isLoading
                        ? _verifyCode
                        : null,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No recibiste un código?  ',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyNegro,
                    ),
                  ),
                  if (_isResending)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryFrances,
                        ),
                      ),
                    )
                  else if (!_canResendLocally &&
                      _verificationKey.currentState == null)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryFrances,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _canResendLocally ? _resendVerificationCode : null,
                      child: Text(
                        _canResendLocally
                            ? 'Reenviar'
                            : 'Reenviar (${_verificationKey.currentState?.formatTimeRemaining() ?? "00:00"})',
                        style: AppTypography.body4.copyWith(
                          color: _canResendLocally
                              ? AppColors.primaryFrances
                              : AppColors.greyMedio,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
