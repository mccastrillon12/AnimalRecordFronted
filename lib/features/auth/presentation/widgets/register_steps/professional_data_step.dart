import 'package:flutter/material.dart';
import '../custom_text_field.dart';

class ProfessionalDataStep extends StatelessWidget {
  final TextEditingController professionalCardController;
  final TextEditingController idController;
  final TextEditingController phoneController;

  const ProfessionalDataStep({
    super.key,
    required this.professionalCardController,
    required this.idController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          label: 'Número de Tarjeta Profesional',
          hint: '123456789',
          controller: professionalCardController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Número de Identificación (C.C.)',
          hint: '1037123123',
          controller: idController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Número de celular',
          hint: '300 123 4567',
          controller: phoneController,
        ),
      ],
    );
  }
}
