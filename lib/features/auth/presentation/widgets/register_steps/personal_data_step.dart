import 'package:flutter/material.dart';
import '../custom_text_field.dart';

class PersonalDataStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;

  const PersonalDataStep({
    super.key,
    required this.nameController,
    required this.emailController,
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
        const CustomTextField(
          label: 'País de residencia',
          hint: 'Colombia',
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
        const SizedBox(height: 16),
        const CustomTextField(
          label: 'Ciudad de residencia',
          hint: 'Medellín, Antioquia',
          suffixIcon: Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }
}
