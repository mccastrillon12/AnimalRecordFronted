import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../custom_text_field.dart';
import 'owner_method_selection_step.dart';
import '../country_dropdown.dart';
import '../id_selector.dart';

class OwnerPersonalDataStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final TextEditingController idController;
  final AccessMethod selectedMethod;

  const OwnerPersonalDataStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.countryController,
    required this.idController,
    required this.selectedMethod,
  });

  @override
  State<OwnerPersonalDataStep> createState() => _OwnerPersonalDataStepState();
}

class _OwnerPersonalDataStepState extends State<OwnerPersonalDataStep> {
  @override
  void initState() {
    super.initState();
    // Initialize country controller with default Colombia value
    if (widget.countryController.text.isEmpty) {
      widget.countryController.text = 'Colombia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre completo
        CustomTextField(
          label: 'Nombre completo',
          hint: 'Jhon Doe',
          controller: widget.nameController,
        ),

        const SizedBox(height: AppSpacing.m),

        // País de residencia
        CountryDropdown(
          label: 'País de residencia',
          value: _getCountryCode(),
          countries: CountryOption.all,
          onChanged: (value) {
            if (value != null) {
              final country = CountryOption.all.firstWhere(
                (c) => c.code == value,
              );
              widget.countryController.text = _getCountryName(country.code);
            }
          },
        ),

        const SizedBox(height: AppSpacing.m),

        // Identificación
        IdSelector(idController: widget.idController),

        const SizedBox(height: AppSpacing.m),

        // Email (condicional)
        if (widget.selectedMethod == AccessMethod.phone) ...[
          CustomTextField(
            label: 'Correo electrónico (Opcional)',
            hint: 'ejemplo@correo.com',
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        // Teléfono (condicional)
        if (widget.selectedMethod == AccessMethod.email) ...[
          _buildPhoneField(isOptional: true),
        ],
      ],
    );
  }

  // Helper to get country code from full name
  String _getCountryCode() {
    final countryName = widget.countryController.text;
    if (countryName == 'Colombia' || countryName.isEmpty) return 'COP';
    if (countryName == 'Estados Unidos') return 'USA';
    if (countryName == 'México') return 'MEX';
    return 'COP'; // Default
  }

  // Helper to get country name from code
  String _getCountryName(String code) {
    switch (code) {
      case 'COP':
        return 'Colombia';
      case 'USA':
        return 'Estados Unidos';
      case 'MEX':
        return 'México';
      default:
        return 'Colombia';
    }
  }

  Widget _buildPhoneField({bool isOptional = false}) {
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
          child: CustomTextField(
            label: isOptional
                ? 'Número de celular (Opcional)'
                : 'Número de celular',
            hint: '(+57) 310 123 45 67',
            controller: widget.phoneController,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}
