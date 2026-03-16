import 'package:animal_record/features/auth/presentation/pages/check_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/presentation/widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/layout/fixed_bottom_action_layout.dart';
import 'package:animal_record/core/utils/mixed_email_phone_input_formatter.dart';
import 'package:animal_record/core/utils/string_formatters.dart';
import 'package:animal_record/core/utils/validation_utils.dart';

class ForgotPinScreen extends StatefulWidget {
  final String identifier;

  const ForgotPinScreen({super.key, required this.identifier});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  late final TextEditingController _identifierController;
  bool _isValidInput = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.identifier);
    _identifierController.addListener(_validateInput);
    // Initial validation
    _validateInput();
  }

  @override
  void dispose() {
    _identifierController.removeListener(_validateInput);
    _identifierController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final value = _identifierController.text.trim();
    setState(() {
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

  void _handleForgotPin() {
    if (_isValidInput) {
      final identifier = StringFormatters.cleanMixedIdentifier(
        _identifierController.text.trim(),
      );
      context.read<AuthBloc>().add(ForgotPinRequested(identifier));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is ForgotPinSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CheckMessagesScreen(
                email: _identifierController.text.trim(),
                isPinFlow: true,
              ),
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
            title: 'Cambiar PIN',
            subtitle: Text(
              'Te enviaremos las instrucciones para que puedas configurar un nuevo PIN.',
              style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
              textAlign: TextAlign.center,
            ),
            child: Form(
              key: _formKey,
              child: FixedBottomActionLayout(
                bottomChild: CustomButton(
                  text: 'Enviar',
                  isLoading: isLoading,
                  onPressed: _isValidInput && !isLoading ? _handleForgotPin : null,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxxl),
                      CustomTextField(
                        label: 'Correo electrónico o celular',
                        hint: 'Correo / Celular',
                        controller: _identifierController,
                        labelStyle: AppTypography.body6,
                        borderColor: AppColors.greyMedio,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 50,
                        inputFormatters: [MixedEmailPhoneInputFormatter()],
                        validator: ValidationUtils.validateEmailOrPhone,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
