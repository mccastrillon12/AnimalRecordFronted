import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';

class PinEntryScreen extends StatefulWidget {
  final String identifier; // Email to display

  const PinEntryScreen({super.key, required this.identifier});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  String _currentPin = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    final pin = _controllers.map((c) => c.text).join();

    setState(() {
      _currentPin = pin;
      _errorMessage = null;
    });
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    if (_currentPin.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await sl<TokenStorage>().getUserId();
      if (userId != null) {
        final isValid = await sl<TokenStorage>().validateUserPin(
          userId,
          _currentPin,
        );

        if (!mounted) return;

        if (isValid) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          setState(() {
            _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
            // Clear fields validation failed
            for (var c in _controllers) {
              c.clear();
            }
            _currentPin = '';
            _focusNodes[0].requestFocus();
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error de sesión. Por favor inicia sesión nuevamente.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al validar PIN';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: true, // As per image background, keeping style consistent
      showCancelButton: false,
      onBack: () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text('Ingresa tu PIN', style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.identifier,
              style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // PIN Input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTypography.heading2,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.greyMedio,
                          ),
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
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _onBackspace(index);
                        } else {
                          _onCodeChanged(index, value);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                _errorMessage!,
                style: AppTypography.body4.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            CustomButton(
              text: 'Ingresar',
              isLoading: _isLoading,
              onPressed: _currentPin.length == 4 ? _handleVerify : null,
            ),

            const SizedBox(height: AppSpacing.l),

            TextButton(
              onPressed: () {
                // Logic for forgotten PIN? Maybe logout?
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: Text(
                '¿Olvidaste el PIN?',
                style: AppTypography.body3.copyWith(
                  color: AppColors.primaryFrances,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
