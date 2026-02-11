import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_form_container.dart';
import '../widgets/country_dropdown.dart';
import '../widgets/id_selector.dart';
import '../widgets/phone_input_field.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/custom_button.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../locations/presentation/cubit/locations_cubit.dart';
import '../../../locations/presentation/cubit/locations_state.dart';
import '../../../locations/domain/entities/country_entity.dart';
import 'package:animal_record/core/utils/error_display.dart';

class SocialRegisterCompletionScreen extends StatefulWidget {
  final String name;
  final String email;
  final String preAuthToken;
  final String providerName; // e.g., 'Google'

  const SocialRegisterCompletionScreen({
    super.key,
    required this.name,
    required this.email,
    required this.preAuthToken,
    this.providerName = 'Google',
  });

  @override
  State<SocialRegisterCompletionScreen> createState() =>
      _SocialRegisterCompletionScreenState();
}

class _SocialRegisterCompletionScreenState
    extends State<SocialRegisterCompletionScreen> {
  final _countryController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();

  // Name and Email controllers for display (read-only)
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  String? _selectedPhoneCountryId;
  String _selectedIdType = 'C.C.';
  String? _idErrorText;
  String? _phoneErrorText;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);

    // Fetch countries
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validateInternal() {
    bool isValid = true;
    setState(() {
      _idErrorText = null;
      _phoneErrorText = null;
    });

    if (_countryController.text.isEmpty) {
      isValid = false;
    }

    if (_idController.text.trim().isEmpty) {
      setState(() => _idErrorText = 'Campo requerido');
      isValid = false;
    }

    if (_phoneController.text.isNotEmpty) {
      final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7) {
        setState(() => _phoneErrorText = 'Número inválido');
        isValid = false;
      }
    }

    return isValid;
  }

  void _onSubmit() {
    if (!_validateInternal()) return;

    // Use phone number from controller directly
    String phoneWithDialCode = _phoneController.text.trim();

    // Mapping display type to backend code
    String idType = 'CC';
    if (_selectedIdType == 'C.E.') idType = 'CE';
    if (_selectedIdType == 'Pasaporte') idType = 'PAS';

    final Map<String, dynamic> data = {
      'preAuthToken': widget.preAuthToken,
      'identificationNumber': _idController.text.trim(),
      'identificationType': idType,
      'cellPhone': _phoneController.text.trim().isEmpty
          ? ""
          : phoneWithDialCode,
      'country': _countryController.text,
      'city': '',
      'roles': ['PROPIETARIO_MASCOTA'],
    };

    context.read<AuthBloc>().add(SocialRegisterSubmitted(data));
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess && !_isNavigating) {
            _isNavigating = true;
            ErrorDisplay.showSuccess(context, 'Registro vía Google exitoso.');
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthError) {
            ErrorDisplay.showError(context, state.message);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Finaliza tu registro - Propietario',
                      style: AppTypography.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Estos han sido los datos recopilados de tu cuenta de ${widget.providerName}, completa los datos faltantes para continuar:',
                      style: AppTypography.body4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    CustomTextField(
                      label: 'Nombre completo',
                      controller: _nameController,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    CustomTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    BlocBuilder<LocationsCubit, LocationsState>(
                      builder: (context, state) {
                        if (state is LocationsLoaded) {
                          if (_countryController.text.isEmpty &&
                              state.countries.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                final colombia = state.countries
                                    .cast<CountryEntity>()
                                    .firstWhere(
                                      (c) => c.name.toLowerCase().contains(
                                        'colombia',
                                      ),
                                      orElse: () => state.countries.first,
                                    );
                                setState(() {
                                  _countryController.text = colombia.id;
                                  _selectedPhoneCountryId = colombia.id;
                                });
                              }
                            });
                          }

                          return Column(
                            children: [
                              CountryDropdown(
                                label: 'País de residencia',
                                value: _countryController.text.isEmpty
                                    ? (state.countries.isNotEmpty
                                          ? state.countries.first.id
                                          : null)
                                    : _countryController.text,
                                countries: state.countries,
                                enabled: false,
                                width: double.infinity,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _countryController.text = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.m),

                              IdSelector(
                                idController: _idController,
                                initialIdType: _selectedIdType,
                                onIdTypeChanged: (val) {
                                  setState(() => _selectedIdType = val);
                                },
                                errorText: _idErrorText,
                              ),
                              const SizedBox(height: AppSpacing.m),

                              PhoneInputField(
                                label: 'Número de celular (Opcional)',
                                controller: _phoneController,
                                countries: state.countries,
                                selectedCountryId:
                                    _selectedPhoneCountryId ??
                                    (state.countries.isNotEmpty
                                        ? state.countries.first.id
                                        : null),
                                onCountryChanged: (val) {
                                  setState(() => _selectedPhoneCountryId = val);
                                },
                                maxLength: 15,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                errorText: _phoneErrorText,
                              ),
                            ],
                          );
                        } else if (state is LocationsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          return const Text('Error cargando países');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.xxl,
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _idController,
                    builder: (context, value, _) {
                      final bool isIdFilled = value.text.trim().isNotEmpty;

                      return CustomButton(
                        text: 'Finalizar',
                        isLoading: state is AuthLoading,
                        onPressed: isIdFilled ? _onSubmit : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
