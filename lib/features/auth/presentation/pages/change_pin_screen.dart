import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _currentStep = 1; // 1: Old + New, 2: Confirm
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
  void dispose() {
    for (var c in _oldPinControllers) c.dispose();
    for (var c in _newPinControllers) c.dispose();
    for (var c in _confirmPinControllers) c.dispose();
    for (var f in _oldPinFocusNodes) f.dispose();
    for (var f in _newPinFocusNodes) f.dispose();
    for (var f in _confirmPinFocusNodes) f.dispose();
    super.dispose();
  }

  void _onOldPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _oldPinFocusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == 3) {
      _newPinFocusNodes[0].requestFocus();
    }
    _updatePins();
  }

  void _onNewPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _newPinFocusNodes[index + 1].requestFocus();
    }
    _updatePins();
  }

  void _onConfirmPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _confirmPinFocusNodes[index + 1].requestFocus();
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
        if (state is AuthSuccess && state.pinChangeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN cambiado exitosamente')),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep == 2)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() => _currentStep = 1),
                      )
                    else
                      const SizedBox(width: 48),
                    Text(
                      _currentStep == 1 ? 'Cambiar PIN' : 'Confirmar PIN',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
                ),
              ),

              // Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<AuthBloc, AuthState>(
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
                          : (_currentStep == 1
                                ? _handleContinue
                                : _handleChange),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text('Ingrese su PIN actual', style: AppTypography.body3),
        const SizedBox(height: 16),
        _buildPinFields(
          _oldPinControllers,
          _oldPinFocusNodes,
          _onOldPinChanged,
        ),
        const SizedBox(height: 48),
        Text(
          'Escoja 4 números nuevos para cambiar tu PIN.',
          style: AppTypography.body3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildPinFields(
          _newPinControllers,
          _newPinFocusNodes,
          _onNewPinChanged,
        ),
        if (_errorMessage != null) _buildError(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Confirme los 4 números escogidos del nuevo PIN.',
          style: AppTypography.body3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildPinFields(
          _confirmPinControllers,
          _confirmPinFocusNodes,
          _onConfirmPinChanged,
        ),
        if (_errorMessage != null) _buildError(),
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
        return Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: true,
            decoration: InputDecoration(
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.greyMedio),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryFrances,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => onChanged(index, value),
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
        style: AppTypography.body4.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}
