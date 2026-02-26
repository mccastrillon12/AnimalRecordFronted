import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import '../country_dropdown.dart';

class PersonalDataStep extends StatefulWidget {
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
  State<PersonalDataStep> createState() => _PersonalDataStepState();
}

class _PersonalDataStepState extends State<PersonalDataStep> {
  @override
  void initState() {
    super.initState();
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationsCubit, LocationsState>(
      listener: (context, state) {
        if (state is LocationsLoaded && state.countries.isNotEmpty) {
          if (widget.countryController.text.isEmpty) {
            final colombia = state.countries.cast<CountryEntity>().firstWhere(
              (c) => c.name.toLowerCase().contains('colombia'),
              orElse: () => state.countries.first,
            );
            widget.countryController.text = colombia.id;
          }
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            CustomTextField(
              label: 'Nombre completo',
              hint: 'Valentina Rios',
              controller: widget.nameController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
              controller: widget.emailController,
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            if (state is LocationsLoaded)
              CountryDropdown(
                label: 'País de residencia',
                value: widget.countryController.text.isEmpty
                    ? (state.countries.isNotEmpty
                          ? state.countries.first.id
                          : null)
                    : widget.countryController.text,
                countries: state.countries,
                enabled: false,
                width: double.infinity,
                onChanged: null,
              )
            else if (state is LocationsLoading)
              const Center(child: CircularProgressIndicator())
            else
              CustomTextField(
                label: 'País de residencia',
                hint: 'Colombia',
                controller: widget.countryController,
                enabled: false,
              ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Ciudad de residencia',
              hint: 'Medellín, Antioquia',
              controller: widget.cityController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Número de Identificación (C.C.)',
              hint: '1037123456',
              controller: widget.idController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Número de celular',
              hint: '3001234567',
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 50,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        );
      },
    );
  }
}
