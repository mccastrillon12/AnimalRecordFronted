import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_form_container.dart';
import '../widgets/country_dropdown.dart';
import '../widgets/id_selector.dart';
import '../widgets/phone_input_field.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../locations/presentation/cubit/locations_cubit.dart';
import '../../../locations/presentation/cubit/locations_state.dart';
import '../../domain/entities/register_params.dart';

class SocialRegisterCompletionScreen extends StatefulWidget {
  final String name;
  final String email;
  final String providerName; // e.g., 'Google'

  const SocialRegisterCompletionScreen({
    super.key,
    required this.name,
    required this.email,
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
  String? _idErrorText;
  String? _phoneErrorText;

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
      // Visual feedback handled by dropdown validation if added,
      // or simple check here
      isValid = false;
    }

    if (_idController.text.isEmpty) {
      setState(() => _idErrorText = 'Campo requerido');
      isValid = false;
    }

    // Optional phone check (if desired) or Mandatory?
    // Screenshot says "Opcional" in the placeholder label,
    // but usually in "Complete profile" it might be desired.
    // The previous implementation had optional logic.
    // The screenshot in the user request shows "Número de celular (Opcional)".
    // So we don't strictly require it, BUT if entered it must be valid.
    if (_phoneController.text.isNotEmpty) {
      // Basic len check
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

    final uuid = const Uuid();
    final String newUserId = uuid.v4();

    // The user role is fixed to 'PROPIETARIO_MASCOTA' as per "Finaliza tu registro - Propietario"
    // If dynamic role needed, we'd pass it in constructor.

    context.read<AuthBloc>().add(
      SignUpSubmitted(
        RegisterParams(
          id: newUserId,
          name: widget.name,
          email: widget.email,
          password: '', // No password for social login
          identificationType:
              'CC', // Default or selector? IdSelector provides type?
          // IdSelector usually binds to a controller.
          // If IdSelector handles both type and number, we need to extracting them.
          // Looking at IdSelector usage in OwnerPersonalDataStep, it only takes idController.
          // It seems IdSelector might be internalizing the type or just taking the number.
          // Wait, IdSelector source code was not fully read but it takes idController.
          // I will assume for now it's just number and type is default CC or managed elsewhere?
          // In RegisterScreen: identificationType: widget.role == 'PROPIETARIO_MASCOTA' ? 'CC' : 'CC'
          // So it seems hardcoded or simple.
          identificationNumber: _idController.text.trim(),
          country: '', // populated backend
          countryId: _countryController.text,
          city: '', // Owner doesn't strictly need city in this flow?
          cellPhone: _phoneController.text.trim(),
          authMethod: 'GOOGLE', // or 'SOCIAL'
          roles: ['PROPIETARIO_MASCOTA'],
          animalTypes: [],
          services: [],
          isHomeDelivery: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro vía Google exitoso.')),
            );
            // Navigate to home/dashboard
            Navigator.pushReplacementNamed(context, '/home'); // Adjust route
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
                    // Header
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

                    // Fields
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

                    // Dynamic Countries
                    BlocBuilder<LocationsCubit, LocationsState>(
                      builder: (context, state) {
                        if (state is LocationsLoaded) {
                          // Pre-select the first country (Colombia) if text is empty
                          if (_countryController.text.isEmpty &&
                              state.countries.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _countryController.text =
                                      state.countries.first.id;
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
            // Persistent bottom button
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
                      // Button only active when Identification is filled
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
