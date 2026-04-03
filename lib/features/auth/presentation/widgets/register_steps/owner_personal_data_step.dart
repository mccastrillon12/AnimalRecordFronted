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
import '../../cubit/register_cubit.dart';
import '../../cubit/register_state.dart';

class OwnerPersonalDataStep extends StatefulWidget {
  final bool showOptionalEmail;
  final bool showOptionalPhone;
  final FocusNode? phoneFocusNode;

  const OwnerPersonalDataStep({
    super.key,
    this.showOptionalEmail = false,
    this.showOptionalPhone = false,
    this.phoneFocusNode,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationsCubit, LocationsState>(
      builder: (context, locState) {
        return BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, registerState) {
            final cubit = context.read<RegisterCubit>();
            
            if (locState is LocationsLoaded && locState.countries.isNotEmpty && registerState.countryId.isEmpty) {
              final colombia = locState.countries.cast<CountryEntity>().firstWhere(
                (c) => c.name.toLowerCase().contains('colombia'),
                orElse: () => locState.countries.first,
              );
              Future.microtask(() => cubit.countryIdChanged(colombia.id));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Nombre completo',
                  hint: 'Jhon Doe',
                  initialValue: registerState.name.value,
                  onChanged: cubit.nameChanged,
                  errorText: registerState.isNameAttempted && registerState.name.isNotValid ? 'Requerido' : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.m),

                if (locState is LocationsLoaded) ...[
                  CountryDropdown(
                    label: 'País de residencia',
                    value: locState.countries.isNotEmpty
                        ? locState.countries.cast<CountryEntity>().firstWhere(
                            (c) => c.name.toLowerCase().contains('colombia'),
                            orElse: () => locState.countries.first,
                          ).id
                        : null,   // Siempre Colombia, fijo
                    enabled: false,
                    countries: locState.countries,
                    width: double.infinity,
                    onChanged: null,
                  ),
                ] else if (locState is LocationsLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (locState is LocationsError) ...[
                  Text('Error: ${locState.message}'),
                ],

                const SizedBox(height: AppSpacing.m),

                IdSelector(
                  initialValue: registerState.identificationNumber.value,
                  onChanged: cubit.identificationNumberChanged,
                  errorText: registerState.idError 
                      ? 'ID ya registrado'
                      : (registerState.isIdAttempted && registerState.identificationNumber.isNotValid 
                          ? 'Requerido' 
                          : null),
                  hideErrorText: registerState.idError,
                  onIdTypeChanged: cubit.identificationTypeChanged,
                  initialIdType: registerState.identificationType,
                ),

                const SizedBox(height: AppSpacing.m),

                if (widget.showOptionalEmail) ...[
                  CustomTextField(
                    label: 'Correo electrónico (Opcional)',
                    hint: 'ejemplo@correo.com',
                    initialValue: registerState.email.value,
                    onChanged: cubit.emailChanged,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 50,
                    errorText: registerState.emailError
                        ? 'Email ya registrado'
                        : (registerState.isEmailAttempted && registerState.email.isNotValid 
                            ? 'Introduzca una dirección de correo electrónico válida' 
                            : null),
                    hideErrorText: registerState.emailError,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],

                if (widget.showOptionalPhone) ...[
                  if (locState is LocationsLoaded)
                    PhoneInputField(
                      label: 'Número de celular (Opcional)',
                      initialValue: registerState.phone.value,
                      onChanged: cubit.phoneChanged,
                      focusNode: widget.phoneFocusNode,
                      countries: locState.countries,
                      selectedCountryId: registerState.phoneCountryId.isNotEmpty
                          ? registerState.phoneCountryId
                          : (locState.countries.isNotEmpty ? locState.countries.first.id : null),
                      onCountryChanged: (val) {
                        if (val != null) cubit.phoneCountryIdChanged(val);
                      },
                      maxLength: 15,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorText: registerState.phoneError
                          ? 'Celular ya registrado'
                          : (registerState.isPhoneAttempted && registerState.phone.isNotValid && registerState.phone.value.isNotEmpty
                              ? 'Introduzca su número de celular en el formato XXX-XXX-XX-XX' 
                              : null),
                      hideErrorText: registerState.phoneError,
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
