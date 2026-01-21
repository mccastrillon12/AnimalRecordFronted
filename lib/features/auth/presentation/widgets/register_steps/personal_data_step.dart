import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:flutter/services.dart';

class PersonalDataStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;
  final TextEditingController idController;
  final TextEditingController phoneController;

  const PersonalDataStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
    required this.idController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          label: 'Nombre completo',
          hint: 'Valentina Rios',
          controller: nameController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Correo electrónico',
          hint: 'ejemplo@correo.com',
          controller: emailController,
          maxLength: 50,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'País de residencia',
          hint: 'Colombia',
          controller: countryController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Ciudad de residencia',
          hint: 'Medellín, Antioquia',
          controller: cityController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Número de Identificación (C.C.)',
          hint: '1037123456',
          controller: idController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Número de celular',
          hint: '3001234567',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 15,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}
