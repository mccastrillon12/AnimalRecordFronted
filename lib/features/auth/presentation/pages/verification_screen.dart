import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/domain/entities/verify_code_params.dart';
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

  void _verifyCode() {
    final code = _verificationKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código completo de 5 dígitos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyCodeSubmitted(VerifyCodeParams(email: widget.email, code: code)),
    );
  }

  void _resendVerificationCode() {
    // TODO: Implement resend code logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: true,
      onBack: () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
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
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
              ),
              const SizedBox(height: AppSpacing.xxl),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return CustomButton(
                    text: 'Verificar',
                    isLoading: state is AuthLoading,
                    onPressed: _verifyCode,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
