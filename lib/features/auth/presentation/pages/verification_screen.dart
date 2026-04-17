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
import 'welcome_social_page.dart';

class VerificationScreen extends StatefulWidget {
  final String identifier;
  final int? timeRemaining;

  const VerificationScreen({
    super.key,
    required this.identifier,
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
  bool _isNavigating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _canResendLocally = widget.timeRemaining == null;
  }

  void _onCodeChanged() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
    setState(() {
      _isCodeComplete =
          _verificationKey.currentState?.isCodeComplete() ?? false;
    });
  }

  void _onTimerChanged() {
    setState(() {
      _canResendLocally = _verificationKey.currentState?.canResend ?? true;
    });
  }

  void _verifyCode() {
    final code = _verificationKey.currentState?.getCode() ?? '';

    if (code.length != 5) {
      setState(() {
        _errorMessage = 'Por favor ingresa el código completo de 5 dígitos';
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9]{5}$').hasMatch(code)) {
      setState(() {
        _errorMessage = 'El código debe ser alfanumérico';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(
      VerifyCodeSubmitted(
        VerifyCodeParams(identifier: widget.identifier, code: code),
      ),
    );
  }

  void _resendVerificationCode() {
    setState(() {
      _isResending = true;
    });

    context.read<AuthBloc>().add(ResendCodeSubmitted(widget.identifier));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: true,
      showCancelButton: false,
      onBack: () => Navigator.pop(context),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && !_isNavigating) {
            _isNavigating = true;
            ErrorDisplay.showSuccess(context, '¡Verificación exitosa!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WelcomeSocialPage(userName: state.user.name),
              ),
            );
          } else if (state is ResendCodeSuccess) {
            _verificationKey.currentState?.restartTimer(180000);

            setState(() {
              _isResending = false;
              _canResendLocally = false;
            });
          } else if (state is AuthError) {
            setState(() {
              _isResending = false;
              _errorMessage =
                  'Código inválido.\nRevisa los dígitos y vuelve a intentarlo.';
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    VerificationStep(
                      key: _verificationKey,
                      identifier: widget.identifier,
                      onResendCode: _resendVerificationCode,
                      initialTimeRemaining: widget.timeRemaining,
                      onCodeChanged: _onCodeChanged,
                      onTimerChanged: _onTimerChanged,
                      isResending: _isResending,
                      hasError: _errorMessage != null,
                      errorMessage: _errorMessage,
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
                    const SizedBox(height: AppSpacing.xxl),
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
                            onTap: _canResendLocally
                                ? _resendVerificationCode
                                : null,
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
          ],
        ),
      ),
    );
  }
}
