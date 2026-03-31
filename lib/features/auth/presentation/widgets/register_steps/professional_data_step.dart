import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../tag_input_widget.dart';
import '../../cubit/register_cubit.dart';
import '../../cubit/register_state.dart';

class ProfessionalDataStep extends StatelessWidget {
  final GlobalKey<TagInputWidgetState>? animalTypesKey;
  final GlobalKey<TagInputWidgetState>? servicesKey;

  const ProfessionalDataStep({
    super.key,
    this.animalTypesKey,
    this.servicesKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        return Column(
          children: [
            CustomTextField(
              label: 'Número de Tarjeta Profesional',
              hint: '123456789',
              initialValue: state.professionalCard.value,
              onChanged: cubit.professionalCardChanged,
            ),
            const SizedBox(height: AppSpacing.m),
            TagInputWidget(
              key: animalTypesKey,
              label: 'Tipos de animales',
              hint: 'Ej: Canino, Felino',
              tags: state.animalTypes,
              onTagsChanged: cubit.animalTypesChanged,
            ),
            const SizedBox(height: AppSpacing.m),
            TagInputWidget(
              key: servicesKey,
              label: 'Servicios',
              hint: 'Ej: Consulta general, Cirugía',
              tags: state.services,
              onTagsChanged: cubit.servicesChanged,
            ),
          ],
        );
      },
    );
  }
}
