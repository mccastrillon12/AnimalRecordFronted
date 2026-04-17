import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../widgets/auth_form_container.dart';
import '../../../../core/widgets/layout/fixed_bottom_action_layout.dart';
import 'check_messages_screen.dart';
import 'package:animal_record/core/utils/string_formatters.dart';
import 'package:animal_record/core/utils/mixed_email_phone_input_formatter.dart';
import 'package:animal_record/core/utils/validation_utils.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
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
  bool _isValidInput = false;
  bool _showPrefix = false;
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateInput);
    _emailController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final value = _emailController.text.trim();
    setState(() {
      _showPrefix = value.isNotEmpty &&
          RegExp(r'^[0-9]').hasMatch(value) &&
          !value.contains('@');
      _isValidInput = _isValidEmailFormat(value) || _isValidPhoneFormat(value);
    });
  }

  bool _isValidEmailFormat(String value) {
    if (value.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  bool _isValidPhoneFormat(String value) {
    if (value.isEmpty) return false;
    final cleanValue = StringFormatters.cleanMixedIdentifier(value);
    final phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
    return phoneRegex.hasMatch(cleanValue);
  }

  void _handleSend() {
    if (_isValidInput) {
      final rawValue = _emailController.text.trim();
      String identifier = rawValue;

      if (!identifier.contains('@')) {
        identifier = identifier.replaceAll(RegExp(r'[\-\s\(\)]'), '');
        if (!identifier.startsWith('+')) {
          identifier = '+57$identifier';
        }
      }

      context.read<AuthBloc>().add(ForgotPasswordRequested(identifier));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ErrorDisplay.showError(context, state.message);
        } else if (state is ForgotPasswordSuccess) {
          final identifier = StringFormatters.cleanMixedIdentifier(
            _emailController.text.trim(),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckMessagesScreen(email: identifier),
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
              'Te enviaremos las instrucciones para que\npuedas configurar una nueva contraseña.',
              textAlign: TextAlign.center,
              style: AppTypography.body4,
            ),
            addInternalPadding: false,
            child: FixedBottomActionLayout(
              bottomChild: CustomButton(
                text: 'Enviar',
                isLoading: isLoading,
                onPressed: _isValidInput && !isLoading ? _handleSend : null,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    CustomTextField(
                      label: 'Correo electrónico o celular',
                      hint: 'Correo / Celular',
                      controller: _emailController,
                      labelStyle: AppTypography.body6,
                      borderColor: AppColors.greyMedio,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 50,
                      validator: ValidationUtils.validateEmailOrPhone,
                      inputFormatters: [MixedEmailPhoneInputFormatter()],
                      validationDelay: const Duration(seconds: 2),
                      prefixIcon: _showPrefix
                          ? Padding(
                              padding: const EdgeInsets.only(left: 12, right: 4),
                              child: Text(
                                '(+57)',
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.greyBordes,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const KeyboardSpacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
