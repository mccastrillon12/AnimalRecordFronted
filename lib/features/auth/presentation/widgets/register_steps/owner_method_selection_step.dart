import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../custom_text_field.dart';
import '../country_dropdown.dart';

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

        const SizedBox(height: AppSpacing.m),

        // Phone option
        _buildMethodOption(
          method: AccessMethod.phone,
          title: 'Número celular',
          icon: Icons.phone_android_outlined,
        ),

        const SizedBox(height: AppSpacing.xl),

        // Conditional fields based on selection
        if (_selectedMethod == AccessMethod.email) ...[
          _buildEmailField(),
        ] else if (_selectedMethod == AccessMethod.phone) ...[
          _buildPhoneFields(),
        ],
      ],
    );
  }

  Widget _buildMethodOption({
    required AccessMethod method,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
        widget.onMethodChanged(method);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryFrances
                      : AppColors.greyMedio,
                  width: isSelected ? 7 : 2,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.m),

            // Title
            Expanded(
              child: Text(
                title,
                style: AppTypography.body4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo electrónico',
          style: AppTypography.body5.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),

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

  Widget _buildPhoneFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector using reusable component
        Expanded(
          flex: 2,
          child: CountryDropdown(
            label: 'País',
            value: 'COP',
            countries: CountryOption.onlyColombia,
            onChanged: null, // Only Colombia for now
          ),
        ),

        const SizedBox(width: AppSpacing.m),

        // Phone number field
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Número de celular',
                style: AppTypography.body5.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: AppSpacing.s),

              CustomTextField(
                label: '',
                hint: '(+57) 310 123 45 67',
                controller: widget.phoneController,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
