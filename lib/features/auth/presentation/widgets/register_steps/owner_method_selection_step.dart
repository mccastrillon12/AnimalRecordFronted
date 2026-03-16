import 'package:animal_record/features/auth/presentation/pages/register_screen.dart';
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

enum AccessMethod { email, phone }

class OwnerMethodSelectionStep extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final String? selectedPhoneCountryId;
  final ValueChanged<String?>? onPhoneCountryChanged;
  final FocusNode? phoneFocusNode;
  final ValueChanged<AccessMethod> onMethodChanged;

  const OwnerMethodSelectionStep({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.countryController,
    required this.onMethodChanged,
    this.selectedPhoneCountryId,
    this.onPhoneCountryChanged,
    this.phoneFocusNode,
  });

  @override
  State<OwnerMethodSelectionStep> createState() =>
      _OwnerMethodSelectionStepState();
}

class _OwnerMethodSelectionStepState extends State<OwnerMethodSelectionStep> {
  AccessMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();

    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccione el método de acceso a su cuenta:',
          style: AppTypography.body4.copyWith(color: AppColors.textPrimary),
        ),

        const SizedBox(height: AppSpacing.l),

        _buildMethodOption(
          method: AccessMethod.email,
          title: 'Correo electrónico',
          icon: Icons.email_outlined,
        ),

        const SizedBox(height: AppSpacing.l),

        _buildMethodOption(
          method: AccessMethod.phone,
          title: 'Número celular',
          icon: Icons.phone_android_outlined,
        ),

        const SizedBox(height: AppSpacing.l),

        if (_selectedMethod == AccessMethod.email) ...[
          _buildEmailField(),
        ] else if (_selectedMethod == AccessMethod.phone) ...[
          BlocBuilder<LocationsCubit, LocationsState>(
            builder: (context, state) {
              if (state is LocationsLoaded) {
                return PhoneInputField(
                  label: 'Número de celular',
                  controller: widget.phoneController,
                  focusNode: widget.phoneFocusNode,
                  countries: state.countries,
                  selectedCountryId: widget.selectedPhoneCountryId,
                  onCountryChanged: widget.onPhoneCountryChanged,
                  maxLength: 50,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) {
                    final registerState = context
                        .findAncestorStateOfType<State<RegisterScreen>>();
                    if (registerState != null) {
                      // ignore: avoid_dynamic_calls
                      (registerState as dynamic)._nextStep();
                    }
                  },
                );
              } else if (state is LocationsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is LocationsError) {
                return Text('Error: ${state.message}');
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMethodOption({
    required AccessMethod method,
    required String title,
    required IconData icon,
  }) {
    return CustomRadioButton<AccessMethod>(
      value: method,
      groupValue: _selectedMethod,
      label: title,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedMethod = value;
          });
          widget.onMethodChanged(value);
        }
      },
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correo electrónico', style: AppTypography.body6),

        const SizedBox(height: AppSpacing.s),

        CustomTextField(
          label: '',
          hint: 'jhondoe@correo.com',
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          maxLength: 50,
        ),
      ],
    );
  }
}
