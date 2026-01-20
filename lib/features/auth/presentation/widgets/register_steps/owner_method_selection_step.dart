import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import '../phone_input_field.dart';

enum AccessMethod { email, phone }

class OwnerMethodSelectionStep extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final ValueChanged<AccessMethod> onMethodChanged;

  const OwnerMethodSelectionStep({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.onMethodChanged,
  });

  @override
  State<OwnerMethodSelectionStep> createState() =>
      _OwnerMethodSelectionStepState();
}

class _OwnerMethodSelectionStepState extends State<OwnerMethodSelectionStep> {
  AccessMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction text
        Text(
          'Seleccione el método de acceso a su cuenta:',
          style: AppTypography.body4.copyWith(color: AppColors.textPrimary),
        ),

        const SizedBox(height: AppSpacing.l),

        // Email option
        _buildMethodOption(
          method: AccessMethod.email,
          title: 'Correo electrónico',
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: AppSpacing.l),

        // Phone option
        _buildMethodOption(
          method: AccessMethod.phone,
          title: 'Número celular',
          icon: Icons.phone_android_outlined,
        ),

        const SizedBox(height: AppSpacing.l),

        // Conditional fields based on selection
        if (_selectedMethod == AccessMethod.email) ...[
          _buildEmailField(),
        ] else if (_selectedMethod == AccessMethod.phone) ...[
          PhoneInputField(
            label: 'Número de celular',
            controller: widget.phoneController,
          ),
        ],
      ],
    );
  }

  Widget _buildMethodOption({
    required AccessMethod method,
    required String title,
    required IconData icon,
  }) {
    return CustomRadioButton<AccessMethod>(
      value: method,
      groupValue: _selectedMethod,
      label: title,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedMethod = value;
          });
          widget.onMethodChanged(value);
        }
      },
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correo electrónico', style: AppTypography.body6),

        const SizedBox(height: AppSpacing.s),

        CustomTextField(
          label: '',
          hint: 'jhondoe@correo.com',
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}
