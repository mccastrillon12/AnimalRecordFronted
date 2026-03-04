import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import '../tag_input_widget.dart';

class ProfessionalDataStep extends StatelessWidget {
  final TextEditingController professionalCardController;
  final List<String> animalTypes;
  final Function(List<String>) onAnimalTypesChanged;
  final List<String> services;
  final Function(List<String>) onServicesChanged;
  final GlobalKey<TagInputWidgetState>? animalTypesKey;
  final GlobalKey<TagInputWidgetState>? servicesKey;

  const ProfessionalDataStep({
    super.key,
    required this.professionalCardController,
    required this.animalTypes,
    required this.onAnimalTypesChanged,
    required this.services,
    required this.onServicesChanged,
    this.animalTypesKey,
    this.servicesKey,
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
        const SizedBox(height: AppSpacing.m),
        TagInputWidget(
          key: animalTypesKey,
          label: 'Tipos de animales',
          hint: 'Ej: Canino, Felino',
          tags: animalTypes,
          onTagsChanged: onAnimalTypesChanged,
        ),
        const SizedBox(height: AppSpacing.m),
        TagInputWidget(
          key: servicesKey,
          label: 'Servicios',
          hint: 'Ej: Consulta general, Cirugía',
          tags: services,
          onTagsChanged: onServicesChanged,
        ),
      ],
    );
  }
}
