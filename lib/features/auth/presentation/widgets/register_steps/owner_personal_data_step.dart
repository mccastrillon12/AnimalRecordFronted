import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import '../country_dropdown.dart';
import '../id_selector.dart';
import '../phone_input_field.dart';
import 'package:flutter/services.dart';

/// A reusable step widget for collecting personal data in registration flows.
///
/// This widget can be customized to show/hide optional fields (email or phone)
/// based on the registration method chosen by the user.
class OwnerPersonalDataStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final TextEditingController idController;

  /// Whether to show the email field as optional (when phone is primary method)
  final bool showOptionalEmail;

  /// Whether to show the phone field as optional (when email is primary method)
  final bool showOptionalPhone;

  /// Error text to display for the phone field
  final String? phoneErrorText;

  /// Error text to display for the email field
  final String? emailErrorText;

  /// Error text to display for the id field
  final String? idErrorText;

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
  });

  @override
  State<OwnerPersonalDataStep> createState() => _OwnerPersonalDataStepState();
}

class _OwnerPersonalDataStepState extends State<OwnerPersonalDataStep> {
  @override
  void initState() {
    super.initState();
    // Fetch countries when the widget initializes
    context.read<LocationsCubit>().fetchCountries();
  }

  String? _selectedPhoneCountryId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationsCubit, LocationsState>(
      listener: (context, state) {
        if (state is LocationsLoaded && state.countries.isNotEmpty) {
          if (widget.countryController.text.isEmpty) {
            widget.countryController.text = state.countries.first.id;
          }
        }
      },
      builder: (context, state) {
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

            // Identificación
            IdSelector(
              idController: widget.idController,
              errorText: widget.idErrorText,
            ),

            const SizedBox(height: AppSpacing.m),

            // Email (condicional)
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

            // Teléfono (condicional)
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
