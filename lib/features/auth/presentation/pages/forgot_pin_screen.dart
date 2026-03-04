import 'package:animal_record/features/auth/presentation/pages/check_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/presentation/widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/layout/fixed_bottom_action_layout.dart';

class ForgotPinScreen extends StatefulWidget {
  final String identifier;

  const ForgotPinScreen({super.key, required this.identifier});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  late final TextEditingController _identifierController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.identifier);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _handleForgotPin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        ForgotPinRequested(_identifierController.text.trim()),
      );
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
              builder: (context) =>
                  CheckMessagesScreen(email: _identifierController.text.trim()),
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
                  onPressed: _handleForgotPin,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        'Correo electrónico o celular',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyNegroV2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _identifierController,
                        style: AppTypography.body3,
                        maxLength: 50,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu correo electrónico',
                          hintStyle: AppTypography.body3.copyWith(
                            color: AppColors.greyBordes,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: AppColors.greyMedio,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: AppColors.greyMedio,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: AppColors.primaryFrances,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.m,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu correo o celular';
                          }
                          return null;
                        },
                      ),
                      const KeyboardSpacer(),
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
