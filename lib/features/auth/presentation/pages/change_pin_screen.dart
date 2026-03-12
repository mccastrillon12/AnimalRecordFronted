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
import 'package:keyboard_actions/keyboard_actions.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _currentStep = 1;
  final List<TextEditingController> _oldPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _newPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _confirmPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _oldPinFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  final List<FocusNode> _newPinFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  final List<FocusNode> _confirmPinFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupFocusNodes(_oldPinFocusNodes, _oldPinControllers, _onOldPinChanged);
    _setupFocusNodes(_newPinFocusNodes, _newPinControllers, _onNewPinChanged);
    _setupFocusNodes(
      _confirmPinFocusNodes,
      _confirmPinControllers,
      _onConfirmPinChanged,
    );
  }

  void _setupFocusNodes(
    List<FocusNode> nodes,
    List<TextEditingController> controllers,
    Function(int, String) onChanged,
  ) {
    for (int i = 0; i < 4; i++) {
      nodes[i].onKeyEvent = (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (controllers[i].text.isEmpty && i > 0) {
            nodes[i - 1].requestFocus();
            controllers[i - 1].clear();
            onChanged(i - 1, '');
            setState(() {});
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (var c in _oldPinControllers) {
      c.dispose();
    }
    for (var c in _newPinControllers) {
      c.dispose();
    }
    for (var c in _confirmPinControllers) {
      c.dispose();
    }
    for (var f in _oldPinFocusNodes) {
      f.dispose();
    }
    for (var f in _newPinFocusNodes) {
      f.dispose();
    }
    for (var f in _confirmPinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOldPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      Future.microtask(() => _oldPinFocusNodes[index + 1].requestFocus());
    } else if (value.isNotEmpty && index == 3) {
      Future.microtask(() => _newPinFocusNodes[0].requestFocus());
    } else if (value.isEmpty && index > 0) {
      Future.microtask(() => _oldPinFocusNodes[index - 1].requestFocus());
    }
    _updatePins();
  }

  void _onNewPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      Future.microtask(() => _newPinFocusNodes[index + 1].requestFocus());
    } else if (value.isEmpty && index > 0) {
      Future.microtask(() => _newPinFocusNodes[index - 1].requestFocus());
    } else if (value.isEmpty && index == 0) {
      Future.microtask(() => _oldPinFocusNodes[3].requestFocus());
    }
    _updatePins();
  }

  void _onConfirmPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      Future.microtask(() => _confirmPinFocusNodes[index + 1].requestFocus());
    } else if (value.isEmpty && index > 0) {
      Future.microtask(() => _confirmPinFocusNodes[index - 1].requestFocus());
    }
    _updatePins();
  }

  void _updatePins() {
    setState(() {
      _oldPin = _oldPinControllers.map((c) => c.text).join();
      _newPin = _newPinControllers.map((c) => c.text).join();
      _confirmPin = _confirmPinControllers.map((c) => c.text).join();
      _errorMessage = null;
    });
  }

  void _handleContinue() {
    if (_oldPin.length == 4 && _newPin.length == 4) {
      setState(() {
        _currentStep = 2;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confirmPinFocusNodes[0].requestFocus();
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
          actions: [..._oldPinFocusNodes, ..._newPinFocusNodes, ..._confirmPinFocusNodes].map((node) => KeyboardActionsItem(
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
        _buildPinFields(
          _oldPinControllers,
          _oldPinFocusNodes,
          _onOldPinChanged,
        ),
        const SizedBox(height: 56),
        Text(
          'Escoja 4 números nuevos para cambiar tu PIN.',
          style: AppTypography.body4,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.l),
        _buildPinFields(
          _newPinControllers,
          _newPinFocusNodes,
          _onNewPinChanged,
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
        _buildPinFields(
          _confirmPinControllers,
          _confirmPinFocusNodes,
          _onConfirmPinChanged,
        ),
        if (_errorMessage != null) _buildError(),
        const KeyboardSpacer(),
      ],
    );
  }

  Widget _buildPinFields(
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
    Function(int, String) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 40,
          height: 40,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofocus: controllers == _oldPinControllers && index == 0,
            maxLength: 1,
            obscureText: true,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: index == 0
                    ? const BorderRadius.horizontal(left: Radius.circular(8))
                    : index == 3
                    ? const BorderRadius.horizontal(right: Radius.circular(8))
                    : BorderRadius.zero,
                borderSide: const BorderSide(color: Color(0xFFA8AFBD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: index == 0
                    ? const BorderRadius.horizontal(left: Radius.circular(8))
                    : index == 3
                    ? const BorderRadius.horizontal(right: Radius.circular(8))
                    : BorderRadius.zero,
                borderSide: const BorderSide(
                  color: AppColors.primaryFrances,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => onChanged(index, value),
            onTap: () {
              controllers[index].selection = TextSelection.fromPosition(
                TextPosition(offset: controllers[index].text.length),
              );
            },
          ),
        );
      }),
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
