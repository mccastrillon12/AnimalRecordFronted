import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import '../tag_input_widget.dart';

class ProfessionalDataStep extends StatelessWidget {
  final TextEditingController professionalCardController;
  final List<String> animalTypes;
  final Function(List<String>) onAnimalTypesChanged;
  final List<String> services;
  final Function(List<String>) onServicesChanged;

  const ProfessionalDataStep({
    super.key,
    required this.professionalCardController,
    required this.animalTypes,
    required this.onAnimalTypesChanged,
    required this.services,
    required this.onServicesChanged,
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
        TagInputWidget(
          label: 'Tipos de animales',
          hint: 'Ej: Canino, Felino',
          tags: animalTypes,
          onTagsChanged: onAnimalTypesChanged,
        ),
        const SizedBox(height: 16),
        TagInputWidget(
          label: 'Servicios',
          hint: 'Ej: Consulta general, Cirugía',
          tags: services,
          onTagsChanged: onServicesChanged,
        ),
      ],
    );
  }
}
