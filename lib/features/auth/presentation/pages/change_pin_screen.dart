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

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _currentStep = 1;
  final FocusNode _oldPinFocusNode = FocusNode();
  final FocusNode _newPinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();

  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  @override
  void dispose() {
    _oldPinFocusNode.dispose();
    _newPinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _onOldPinChanged(String value) {
    if (value.length == 4 && _oldPin.length < 4) {
      Future.microtask(() => _newPinFocusNode.requestFocus());
    }
    setState(() {
      _oldPin = value;
      _errorMessage = null;
    });
  }

  void _onNewPinChanged(String value) {
    if (value.isEmpty && _newPin.length == 1) {
      Future.microtask(() => _oldPinFocusNode.requestFocus());
    }
    setState(() {
      _newPin = value;
      _errorMessage = null;
    });
  }

  void _onConfirmPinChanged(String value) {
    setState(() {
      _confirmPin = value;
      _errorMessage = null;
    });
  }

  void _handleContinue() {
    if (_oldPin.length == 4 && _newPin.length == 4) {
      setState(() {
        _currentStep = 2;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confirmPinFocusNode.requestFocus();
      });
    }
  }

  void _handleChange() {
    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'Los PINs nuevos no coinciden';
      });
      return;
    }

    context.read<AuthBloc>().add(
      ChangePinRequested(oldPin: _oldPin, newPin: _newPin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _errorMessage = state.message);
        }
        if (state is AuthSuccess && state.updateError != null) {
          setState(() => _errorMessage = state.updateError);
        }
        if (state is AuthSuccess && state.pinChangeSuccess) {
          ErrorDisplay.showSuccess(context, 'PIN cambiado exitosamente');
          Navigator.pop(context);
        }
      },
      child: KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: const Color(0xFFD1D5DF),
          nextFocus: false,
          actions: [_oldPinFocusNode, _newPinFocusNode, _confirmPinFocusNode].map((node) => KeyboardActionsItem(
            focusNode: node,
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
          )).toList(),
        ),
        child: AuthFormContainer(
          showLogo: false,
          title: _currentStep == 1 ? 'Cambiar PIN' : 'Confirmar PIN',
        onBack: _currentStep == 2
            ? () => setState(() => _currentStep = 1)
            : null,
        onCancel: () => Navigator.pop(context),
        addInternalPadding: false,
        child: FixedBottomActionLayout(
          bottomChild: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthSuccess && state.isUpdating;
              return CustomButton(
                text: _currentStep == 1 ? 'Continuar' : 'Cambiar',
                isLoading: isLoading,
                onPressed:
                    isLoading ||
                        (_currentStep == 1
                            ? (_oldPin.length != 4 || _newPin.length != 4)
                            : _confirmPin.length != 4)
                    ? null
                    : (_currentStep == 1 ? _handleContinue : _handleChange),
              );
            },
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStep1() {
    return Column(
      children: [
        const SizedBox(height: 56),
        Text('Ingrese su PIN actual', style: AppTypography.body4),
        const SizedBox(height: AppSpacing.l),
        PinInputField(
          pin: _oldPin,
          onChanged: _onOldPinChanged,
          focusNode: _oldPinFocusNode,
          obscureText: true,
        ),
        const SizedBox(height: 56),
        Text(
          'Escoja 4 números nuevos para cambiar tu PIN.',
          style: AppTypography.body4,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.l),
        PinInputField(
          pin: _newPin,
          onChanged: _onNewPinChanged,
          focusNode: _newPinFocusNode,
          obscureText: true,
        ),
        if (_errorMessage != null) _buildError(),
        const KeyboardSpacer(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        const SizedBox(height: 56),
        Text(
          'Confirme los 4 números escogidos del nuevo PIN.',
          style: AppTypography.body4,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.m),
        PinInputField(
          pin: _confirmPin,
          onChanged: _onConfirmPinChanged,
          focusNode: _confirmPinFocusNode,
          obscureText: true,
        ),
        if (_errorMessage != null) _buildError(),
        const KeyboardSpacer(),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        _errorMessage!,
        style: AppTypography.body5.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}
