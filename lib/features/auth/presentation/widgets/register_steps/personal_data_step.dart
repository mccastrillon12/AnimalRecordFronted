import 'package:flutter/material.dart';
import '../custom_text_field.dart';

class PersonalDataStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController countryController;
  final TextEditingController cityController;

  const PersonalDataStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.countryController,
    required this.cityController,
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
      ],
    );
  }
}
