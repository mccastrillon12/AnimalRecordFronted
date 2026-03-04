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
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String _pin = '';
  String? _errorMessage;

  @override
  void dispose() {
    for (var c in _pinControllers) c.dispose();
    for (var f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _pinFocusNodes[index + 1].requestFocus();
    }
    _updatePin();
  }

  void _updatePin() {
    setState(() {
      _pin = _pinControllers.map((c) => c.text).join();
      _errorMessage = null;
    });
  }

  void _handleChange() {
    if (_pin.length == 4) {
      context.read<AuthBloc>().add(
        ResetPinSubmitted(
          identifier: widget.identifier,
          token: widget.token,
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
      child: AuthFormContainer(
        showLogo: false,
        title: 'Confirmar PIN',
        showCancelButton: true,
        addInternalPadding: false,
        child: FixedBottomActionLayout(
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
        ),
      ),
    );
  }

  Widget _buildPinFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 40,
          height: 40,
          child: TextField(
            controller: _pinControllers[index],
            focusNode: _pinFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
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
            onChanged: (value) => _onPinChanged(index, value),
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
