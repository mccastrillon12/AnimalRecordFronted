import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import '../country_dropdown.dart';
import '../phone_input_field.dart';
import '../../cubit/register_cubit.dart';
import '../../cubit/register_state.dart';

class PersonalDataStep extends StatefulWidget {
  final FocusNode? phoneFocusNode;

  const PersonalDataStep({
    super.key,
    this.phoneFocusNode,
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
            
            String? colombiaId;
            if (locState is LocationsLoaded && locState.countries.isNotEmpty) {
              colombiaId = locState.countries.cast<CountryEntity>().firstWhere(
                (c) => c.name.toLowerCase().contains('colombia'),
                orElse: () => locState.countries.first,
              ).id;
            }

            return Column(
              children: [
                CustomTextField(
                  label: 'Nombre completo',
                  hint: 'Valentina Rios',
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
                CustomTextField(
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  initialValue: registerState.email.value,
                  onChanged: cubit.emailChanged,
                  errorText: registerState.emailError 
                      ? 'Email ya registrado' 
                      : (registerState.isEmailAttempted && registerState.email.isNotValid 
                          ? 'Introduzca una dirección de correo electrónico válida' 
                          : null),
                  hideErrorText: registerState.emailError,
                  maxLength: 50,
                ),
                const SizedBox(height: AppSpacing.m),
                if (locState is LocationsLoaded)
                  CountryDropdown(
                    label: 'País de residencia',
                    value: colombiaId,   // Siempre Colombia, fijo
                    countries: locState.countries,
                    enabled: false,
                    width: double.infinity,
                    onChanged: null,
                  )
                else if (locState is LocationsLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  const CustomTextField(
                    label: 'País de residencia',
                    hint: 'Colombia',
                    initialValue: 'Colombia',
                    enabled: false,
                  ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  label: 'Ciudad de residencia',
                  hint: 'Medellín, Antioquia',
                  initialValue: registerState.city.value,
                  onChanged: cubit.cityChanged,
                ),
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  label: 'Número de Identificación (C.C.)',
                  hint: '1037123456',
                  initialValue: registerState.identificationNumber.value,
                  onChanged: cubit.identificationNumberChanged,
                  errorText: registerState.idError
                      ? 'ID ya registrado'
                      : (registerState.isIdAttempted && registerState.identificationNumber.isNotValid 
                          ? 'Requerido' 
                          : null),
                  hideErrorText: registerState.idError,
                  keyboardType: TextInputType.text,
                  maxLength: 50,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                if (locState is LocationsLoaded)
                  PhoneInputField(
                    label: 'Número de celular',
                    initialValue: registerState.phone.value,
                    onChanged: cubit.phoneChanged,
                    countries: locState.countries,
                    selectedCountryId: registerState.phoneCountryId.isNotEmpty
                        ? registerState.phoneCountryId
                        : (locState.countries.isNotEmpty ? locState.countries.first.id : null),
                    onCountryChanged: (val) {
                      if (val != null) cubit.phoneCountryIdChanged(val);
                    },
                    errorText: registerState.phoneError
                        ? 'Celular ya registrado'
                        : (registerState.isPhoneAttempted && registerState.phone.isNotValid 
                            ? 'Introduzca su número de celular en el formato XXX-XXX-XX-XX' 
                            : null),
                    hideErrorText: registerState.phoneError,
                    focusNode: widget.phoneFocusNode,
                    maxLength: 15,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )
                else
                  CustomTextField(
                    label: 'Número de celular',
                    hint: '3001234567',
                    initialValue: registerState.phone.value,
                    onChanged: cubit.phoneChanged,
                    focusNode: widget.phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
