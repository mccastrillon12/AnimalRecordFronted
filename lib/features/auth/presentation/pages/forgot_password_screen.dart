import 'package:flutter/material.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../widgets/auth_form_container.dart';
import 'check_messages_screen.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isValidEmail = false;
  bool _isLoading = false;

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

  Future<void> _handleSend() async {
    if (_isValidEmail && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dataSource = sl<AuthRemoteDataSource>();
        await dataSource.forgotPassword(_emailController.text.trim());

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to check messages screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CheckMessagesScreen(email: _emailController.text.trim()),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ErrorDisplay.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              isLoading: _isLoading,
              onPressed: _isValidEmail && !_isLoading ? _handleSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
