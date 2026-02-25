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
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import '../phone_input_field.dart';

enum AccessMethod { email, phone }

class OwnerMethodSelectionStep extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController countryController;
  final ValueChanged<AccessMethod> onMethodChanged;

  const OwnerMethodSelectionStep({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.countryController,
    required this.onMethodChanged,
  });

  @override
  State<OwnerMethodSelectionStep> createState() =>
      _OwnerMethodSelectionStepState();
}

class _OwnerMethodSelectionStepState extends State<OwnerMethodSelectionStep> {
  AccessMethod? _selectedMethod;
  String? _selectedPhoneCountryId;

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
                if (_selectedPhoneCountryId == null &&
                    state.countries.isNotEmpty) {
                  final colombia = state.countries
                      .cast<CountryEntity>()
                      .firstWhere(
                        (c) => c.name.toLowerCase().contains('colombia'),
                        orElse: () => state.countries.first,
                      );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedPhoneCountryId = colombia.id;
                        widget.countryController.text = colombia.id;
                      });
                    }
                  });
                }

                return PhoneInputField(
                  label: 'Número de celular',
                  controller: widget.phoneController,
                  countries: state.countries,
                  selectedCountryId: _selectedPhoneCountryId,
                  onCountryChanged: (value) {
                    setState(() {
                      _selectedPhoneCountryId = value;
                    });
                  },
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
