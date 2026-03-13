import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/custom_button.dart';
import '../../../../core/widgets/layout/fixed_bottom_action_layout.dart';
import '../widgets/auth_form_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../../../../core/widgets/utils/keyboard_spacer.dart';
import '../../../../core/widgets/inputs/pin_input_field.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:app_links/app_links.dart';

class ResetPinScreen extends StatefulWidget {
  final String identifier;
  final String token;

  const ResetPinScreen({
    super.key,
    required this.identifier,
    required this.token,
  });

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final FocusNode _pinFocusNode = FocusNode();

  String _pin = '';
  String? _errorMessage;
  late String _currentIdentifier;
  late String _currentToken;

  @override
  void initState() {
    super.initState();
    _currentIdentifier = widget.identifier;
    _currentToken = widget.token;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safety Net: if args are missing, try to recover from URI
    if (_currentToken.isEmpty || _currentIdentifier.isEmpty) {
      AppLinks().getLatestLink().then((value) {
        if (value != null && mounted) {
          setState(() {
            if (_currentToken.isEmpty) _currentToken = value.queryParameters['token'] ?? '';
            if (_currentIdentifier.isEmpty) {
              _currentIdentifier = value.queryParameters['identifier'] ?? 
                                   value.queryParameters['email'] ?? '';
              _currentIdentifier = _currentIdentifier.replaceAll(' ', '+');
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    setState(() {
      _pin = value;
      _errorMessage = null;
    });
  }

  void _handleChange() {
    if (_pin.length == 4) {
      context.read<AuthBloc>().add(
        ResetPinSubmitted(
          identifier: _currentIdentifier,
          token: _currentToken,
          newPin: _pin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _errorMessage = state.message);
        }
        if (state is ResetPinSuccess) {
          ErrorDisplay.showSuccess(context, 'PIN restablecido exitosamente');
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
      child: KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: const Color(0xFFD1D5DF),
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _pinFocusNode,
              displayArrows: false,
              displayDoneButton: false,
              toolbarButtons: [
                (node) {
                  return GestureDetector(
                    onTap: () => node.unfocus(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        "Aceptar",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              ],
            )
          ],
        ),
        child: AuthFormContainer(
          showLogo: false,
          title: 'Confirmar PIN',
          showCancelButton: true,
          addInternalPadding: false,
          onCancel: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        child: FixedBottomActionLayout(
          bottomChild: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return CustomButton(
                text: 'Cambiar',
                isLoading: isLoading,
                onPressed: isLoading || _pin.length != 4 ? null : _handleChange,
              );
            },
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Text(
                  'Confirme los 4 números escogidos del nuevo PIN.',
                  style: AppTypography.body3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildPinFields(),
                if (_errorMessage != null) _buildError(),
                const KeyboardSpacer(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPinFields() {
    return PinInputField(
      pin: _pin,
      onChanged: _onPinChanged,
      focusNode: _pinFocusNode,
      obscureText: true,
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        _errorMessage!,
        style: AppTypography.body5.copyWith(
          color: AppColors.error,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
