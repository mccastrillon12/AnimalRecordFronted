import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/auth_form_container.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/domain/entities/login_params.dart';

class PasswordScreen extends StatefulWidget {
  final String identifier; // Email or phone

  const PasswordScreen({super.key, required this.identifier});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
      onBack: () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('¡Login exitoso!')));
            // TODO: Navigate to home screen
            // Navigator.pushReplacementNamed(context, '/home');
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: Text(
                  'Ingresa tu contraseña',
                  style: AppTypography.heading1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Text(
                  widget.identifier,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                child: CustomTextField(
                  label: 'Contraseña',
                  hint: '',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  labelStyle: AppTypography.body6,
                  hintStyle: AppTypography.body4.copyWith(
                    color: AppColors.greyMedio,
                  ),
                  borderColor: AppColors.greyMedio,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'Ingresar',
                      isLoading: state is AuthLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.l),
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to forgot password screen
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
