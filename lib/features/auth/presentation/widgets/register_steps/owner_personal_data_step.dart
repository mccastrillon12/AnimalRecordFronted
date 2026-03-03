import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import '../country_dropdown.dart';
import '../id_selector.dart';
import '../phone_input_field.dart';
import 'package:flutter/services.dart';

class OwnerPersonalDataStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final TextEditingController idController;

  final bool showOptionalEmail;

  final bool showOptionalPhone;

  final String? phoneErrorText;

  final String? emailErrorText;

  final String? idErrorText;

  final ValueChanged<String>? onIdTypeChanged;

  final String? initialIdType;

  const OwnerPersonalDataStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.countryController,
    required this.idController,
    this.showOptionalEmail = false,
    this.showOptionalPhone = false,
    this.phoneErrorText,
    this.emailErrorText,
    this.idErrorText,
    this.onIdTypeChanged,
    this.initialIdType,
  });

  @override
  State<OwnerPersonalDataStep> createState() => _OwnerPersonalDataStepState();
}

class _OwnerPersonalDataStepState extends State<OwnerPersonalDataStep> {
  @override
  void initState() {
    super.initState();

    context.read<LocationsCubit>().fetchCountries();
  }

  String? _selectedPhoneCountryId;

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
            setState(() {
              _selectedPhoneCountryId = colombia.id;
            });
          }
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Nombre completo',
              hint: 'Jhon Doe',
              controller: widget.nameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.m),

            if (state is LocationsLoaded) ...[
              CountryDropdown(
                label: 'País de residencia',
                value: widget.countryController.text.isEmpty
                    ? (state.countries.isNotEmpty
                          ? state.countries.first.id
                          : null)
                    : widget.countryController.text,
                enabled: false,
                countries: state.countries,
                width: double.infinity,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      widget.countryController.text = value;
                    });
                  }
                },
              ),
            ] else if (state is LocationsLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (state is LocationsError) ...[
              Text('Error: ${state.message}'),
            ],

            const SizedBox(height: AppSpacing.m),

            IdSelector(
              idController: widget.idController,
              errorText: widget.idErrorText,
              onIdTypeChanged: widget.onIdTypeChanged,
              initialIdType: widget.initialIdType,
            ),

            const SizedBox(height: AppSpacing.m),

            if (widget.showOptionalEmail) ...[
              CustomTextField(
                label: 'Correo electrónico (Opcional)',
                hint: 'ejemplo@correo.com',
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 50,
                errorText: widget.emailErrorText,
              ),
              const SizedBox(height: AppSpacing.m),
            ],

            if (widget.showOptionalPhone) ...[
              if (state is LocationsLoaded)
                PhoneInputField(
                  label: 'Número de celular (Opcional)',
                  controller: widget.phoneController,
                  countries: state.countries,
                  selectedCountryId:
                      _selectedPhoneCountryId ??
                      (state.countries.isNotEmpty
                          ? state.countries.first.id
                          : null),
                  onCountryChanged: (value) {
                    setState(() {
                      _selectedPhoneCountryId = value;
                    });
                  },
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: widget.phoneErrorText,
                ),
            ],
          ],
        );
      },
    );
  }
}
