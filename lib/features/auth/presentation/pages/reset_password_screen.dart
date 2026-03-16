import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/inputs/password_requirements_validator.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../widgets/auth_form_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:app_links/app_links.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isValid = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _token;
  String? _identifier;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _token = args['token'] as String?;
      _identifier = args['identifier'] as String?;
    } else if (args is String) {
      _token = args;
    }

    // iOS Safety Net: If arguments are missing, try to extract from current URI as fallback
    if ((_token == null || _identifier == null)) {
      AppLinks().getLatestLink().then((value) {
        if (value != null && mounted) {
          setState(() {
            _token ??= value.queryParameters['token'];
            _identifier ??= value.queryParameters['identifier'] ?? 
                           value.queryParameters['email'];
            if (_identifier != null) {
              _identifier = _identifier!.replaceAll(' ', '+');
            }
          });
          
          if (_token != null && _identifier != null) {
            context.read<AuthBloc>().add(
              ValidateResetToken(identifier: _identifier!, token: _token!),
            );
          } else {
             _redirectToExpired();
          }
        } else if (mounted) {
          _redirectToExpired();
        }
      });
    } else if (_token != null && _identifier != null) {
      // Arguments were provided via route, but we still want to be sure it's valid if we didn't come from DeepLinkService
      // or just to be safe. 
      // However, DeepLinkService already validates. To avoid double validation, 
      // we can just trust the arguments for now, but let's at least not show the form 
      // if it was somehow reachable without validation.
      // For now, let's keep it simple: if we have tokens, we show the form.
      // The BlocListener will handle the ResetTokenInvalid state if it was triggered elsewhere.
      setState(() {
        _isValid = true;
      });
    } else {
      _redirectToExpired();
    }
  }

  void _redirectToExpired() {
    Future.microtask(
      () => Navigator.pushReplacementNamed(
        context,
        '/link-expired',
        arguments: {'isPinFlow': false},
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validateForm);
    _confirmPasswordController.removeListener(_validateForm);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      if (_confirmPasswordController.text.isNotEmpty &&
          _passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Las contraseñas no coinciden';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  bool get _isFormValid {
    return _isPasswordValid(_passwordController.text) &&
        _passwordController.text == _confirmPasswordController.text &&
        _passwordController.text.isNotEmpty;
  }

  void _handleChangePassword() {
    if (_token == null || _identifier == null) {
      ErrorDisplay.showError(
        context,
        'Enlace inválido o incompleto. Por favor solicite uno nuevo.',
      );
      return;
    }

    if (_isFormValid) {
      context.read<AuthBloc>().add(
        ResetPasswordSubmitted(
          identifier: _identifier!,
          token: _token!,
          newPassword: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ResetTokenValid) {
          setState(() {
            _isValid = true;
          });
        } else if (state is ResetPasswordSuccess) {
          ErrorDisplay.showSuccess(context, 'Su contraseña se cambio con exito Inicia sesion');
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (state is ResetTokenInvalid) {
          Navigator.pushReplacementNamed(
            context,
            '/link-expired',
            arguments: {'isPinFlow': false},
          );
        } else if (state is AuthError) {
          if (state.message.toLowerCase().contains('invalid') ||
              state.message.toLowerCase().contains('inválido') ||
              state.message.toLowerCase().contains('expired') ||
              state.message.toLowerCase().contains('expirado')) {
            Navigator.pushReplacementNamed(
              context,
              '/link-expired',
              arguments: {'isPinFlow': false},
            );
          } else {
            ErrorDisplay.showError(context, state.message);
          }
        }
      },
      child: AuthFormContainer(
        showCancelButton: true,
        showLogo: false,
        title: 'Cambiar contraseña',
        subtitle: Text(
          'Establece tu nueva contraseña para acceder a tu cuenta.',
          style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
          textAlign: TextAlign.center,
        ),
        onCancel: () {
          context.read<AuthBloc>().add(ClearAuthEvent());
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (!_isValid &&
                        (state is AuthInitial || state is AuthLoading)) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_isValid) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.l),
                          CustomTextField(
                            label: 'Nueva contraseña',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            isPassword: true,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.m),

                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _passwordController,
                            builder: (context, value, child) {
                              return PasswordRequirementsValidator(
                                password: value.text,
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.l),
                          CustomTextField(
                            label: 'Confirmar nueva contraseña',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            isPassword: true,
                            errorText: _confirmPasswordError,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const KeyboardSpacer(),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.m,
                bottom: AppSpacing.l,
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (_isValid) {
                    return CustomButton(
                      text: 'Cambiar',
                      isLoading: state is AuthLoading,
                      onPressed: _isFormValid ? _handleChangePassword : null,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
