import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../widgets/auth_form_container.dart';
import 'check_messages_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isValidEmail = false;
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final value = _emailController.text.trim();
    setState(() {
      _isValidEmail = _isValidEmailFormat(value);
    });
  }

  bool _isValidEmailFormat(String value) {
    if (value.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  void _handleSend() {
    if (_isValidEmail) {
      context.read<AuthBloc>().add(
        ForgotPasswordRequested(_emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ErrorDisplay.showError(context, state.message);
        } else if (state is ForgotPasswordSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CheckMessagesScreen(email: _emailController.text.trim()),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthFormContainer(
            showLogo: false,
            showCancelButton: true,
            title: 'Cambiar contraseña',
            subtitle: Text(
              'Te enviaremos las instrucciones para que puedas configurar una nueva contraseña.',
              textAlign: TextAlign.center,
              style: AppTypography.body4,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  CustomTextField(
                    label: 'Correo electrónico o celular',
                    hint: 'marc_doe@hotmail.com',
                    controller: _emailController,
                    labelStyle: AppTypography.body6,
                    hintStyle: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                    borderColor: AppColors.greyMedio,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 50,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  CustomButton(
                    text: 'Enviar',
                    isLoading: isLoading,
                    onPressed: _isValidEmail && !isLoading ? _handleSend : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
