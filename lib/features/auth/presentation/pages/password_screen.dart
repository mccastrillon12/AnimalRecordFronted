import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/domain/entities/login_params.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'verification_screen.dart';
import 'forgot_password_screen.dart';

class PasswordScreen extends StatefulWidget {
  final String identifier;

  const PasswordScreen({super.key, required this.identifier});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isValidPassword = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    setState(() {
      _isValidPassword = _passwordController.text.length >= 8;
    });
  }

  void _handleLogin() {
    final loginParams = LoginParams(
      identifier: widget.identifier,
      password: _passwordController.text,
    );

    context.read<AuthBloc>().add(LoginSubmitted(loginParams));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: true,
      showCancelButton: false,
      title: 'Ingresa tu contraseña',
      subtitle: Text(
        widget.identifier,
        style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
      ),
      onBack: () => Navigator.pop(context),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && !_isNavigating) {
            _isNavigating = true;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else if (state is AuthUserNotVerified) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  email: widget.identifier,
                  phoneNumber: null,
                  timeRemaining: state.timeRemaining,
                ),
              ),
            );
          } else if (state is AuthError) {
            ErrorDisplay.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 94),
                child: CustomTextField(
                  label: 'Contraseña',
                  hint: '',
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  labelStyle: AppTypography.body6,
                  hintStyle: AppTypography.body4.copyWith(
                    color: AppColors.greyMedio,
                  ),
                  borderColor: AppColors.greyMedio,
                  onSubmitted: (_) => _handleLogin(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.l),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return CustomButton(
                      text: 'Ingresar',
                      isLoading: isLoading,
                      onPressed: _isValidPassword && !isLoading
                          ? _handleLogin
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '¿Olvidaste la contraseña?',
                    style: AppTypography.body3.copyWith(
                      color: AppColors.primaryFrances,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
