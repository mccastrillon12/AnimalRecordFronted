import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import '../phone_input_field.dart';
import '../../cubit/register_cubit.dart';
import '../../cubit/register_state.dart';

class OwnerMethodSelectionStep extends StatefulWidget {
  final FocusNode? phoneFocusNode;

  const OwnerMethodSelectionStep({
    super.key,
    this.phoneFocusNode,
  });

  @override
  State<OwnerMethodSelectionStep> createState() =>
      _OwnerMethodSelectionStepState();
}

class _OwnerMethodSelectionStepState extends State<OwnerMethodSelectionStep> {
  @override
  void initState() {
    super.initState();
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, registerState) {
        final cubit = context.read<RegisterCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccione el método de acceso a su cuenta:',
              style: AppTypography.body4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.l),
            _buildMethodOption(
              currentMethod: registerState.accessMethod,
              method: AccessMethod.email,
              title: 'Correo electrónico',
              icon: Icons.email_outlined,
              onChanged: cubit.accessMethodChanged,
            ),
            const SizedBox(height: AppSpacing.l),
            _buildMethodOption(
              currentMethod: registerState.accessMethod,
              method: AccessMethod.phone,
              title: 'Número celular',
              icon: Icons.phone_android_outlined,
              onChanged: cubit.accessMethodChanged,
            ),
            const SizedBox(height: AppSpacing.l),
            if (registerState.accessMethod == AccessMethod.email) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Correo electrónico', style: AppTypography.body6),
                  const SizedBox(height: AppSpacing.s),
                  CustomTextField(
                    label: '',
                    hint: 'jhondoe@correo.com',
                    initialValue: registerState.email.value,
                    onChanged: cubit.emailChanged,
                    keyboardType: TextInputType.emailAddress,
                    errorText: registerState.emailError 
                        ? 'Email ya registrado' 
                        : (registerState.isEmailAttempted && registerState.email.isNotValid 
                            ? 'Introduzca una dirección de correo electrónico válida' 
                            : null),
                    hideErrorText: registerState.emailError,
                    maxLength: 50,
                  ),
                ],
              ),
            ] else if (registerState.accessMethod == AccessMethod.phone) ...[
              BlocBuilder<LocationsCubit, LocationsState>(
                builder: (context, locState) {
                  if (locState is LocationsLoaded) {
                    return PhoneInputField(
                      label: 'Número de celular',
                      focusNode: widget.phoneFocusNode,
                      countries: locState.countries,
                      initialValue: registerState.phone.value,
                      onChanged: cubit.phoneChanged,
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
                      maxLength: 15,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    );
                  } else if (locState is LocationsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (locState is LocationsError) {
                    return Text('Error: ${locState.message}');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMethodOption({
    required AccessMethod? currentMethod,
    required AccessMethod method,
    required String title,
    required IconData icon,
    required Function(AccessMethod) onChanged,
  }) {
    return CustomRadioButton<AccessMethod>(
      value: method,
      groupValue: currentMethod,
      label: title,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
