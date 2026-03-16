import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_form_container.dart';
import '../../../../core/widgets/layout/fixed_bottom_action_layout.dart';
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
import '../../../../core/widgets/utils/keyboard_spacer.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/utils/validation_utils.dart';
import 'welcome_social_page.dart';

class SocialRegisterCompletionScreen extends StatefulWidget {
  final String name;
  final String email;
  final String preAuthToken;
  final String providerName;

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

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // ID del país seleccionado en el PhoneInputField (puede ser COL, USA, etc.)
  String? _selectedPhoneCountryId;
  // ID fijo de Colombia para el dropdown de residencia
  String? _colombiaId;

  String _selectedIdType = 'C.C.';
  String? _idErrorText;
  String? _phoneErrorText;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);

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

    final locState = context.read<LocationsCubit>().state;

    String idType = 'CC';
    if (_selectedIdType == 'C.E.') idType = 'CE';
    if (_selectedIdType == 'Pasaporte') idType = 'PAS';

    // Construir cellPhone con indicativo, igual que en edit_profile_screen
    String cellPhone = _phoneController.text.trim();
    if (cellPhone.isNotEmpty && locState is LocationsLoaded) {
      final countryId = _selectedPhoneCountryId;
      if (countryId != null && countryId.isNotEmpty) {
        try {
          final country = locState.countries
              .cast<CountryEntity>()
              .firstWhere((c) => c.id == countryId);

          final prefix = country.dialCode;
          final purePrefix = prefix.replaceAll('+', '');

          // Solo números ingresados por el usuario
          String numbersOnly = cellPhone.replaceAll(RegExp(r'\D'), '');

          // Si el usuario escribió el prefijo a mano, lo quitamos
          if (numbersOnly.startsWith(purePrefix)) {
            numbersOnly = numbersOnly.substring(purePrefix.length);
          }

          cellPhone = '$prefix$numbersOnly';
        } catch (_) {}
      }
    }

    // El country que va al backend es el del selector de teléfono
    // (puede ser USA, Colombia, etc.), NO el de residencia que siempre es Colombia
    final countryToSend = _selectedPhoneCountryId ?? _colombiaId ?? '';

    final Map<String, dynamic> data = {
      'preAuthToken': widget.preAuthToken,
      'identificationNumber': _idController.text.trim(),
      'identificationType': idType,
      'cellPhone': cellPhone.isEmpty ? '' : cellPhone,
      'country': countryToSend,
      'city': '',
      'roles': ['PROPIETARIO_MASCOTA'],
    };

    context.read<AuthBloc>().add(
      SocialRegisterSubmitted(data, nameToUpdate: _nameController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      showLogo: false,
      onBack: () => Navigator.pop(context),
      addInternalPadding: false,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess && !_isNavigating) {
                _isNavigating = true;
                ErrorDisplay.showSuccess(
                  context,
                  'Registro vía ${widget.providerName} exitoso.',
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WelcomeSocialPage(userName: widget.name),
                  ),
                );
              } else if (state is AuthError) {
                ErrorDisplay.showError(context, state.message);
              }
            },
          ),
          BlocListener<LocationsCubit, LocationsState>(
            listener: (context, state) {
              if (state is LocationsLoaded && state.countries.isNotEmpty) {
                // Buscar Colombia y establecerla como país de residencia
                // y como selección inicial del teléfono
                try {
                  final colombia = state.countries
                      .cast<CountryEntity>()
                      .firstWhere(
                        (c) =>
                            c.dialCode == '+57' ||
                            c.name.toLowerCase().contains('colombia'),
                      );
                  setState(() {
                    _colombiaId = colombia.id;
                    _countryController.text = colombia.id;
                    // Solo inicializar si aún no hay selección
                    _selectedPhoneCountryId ??= colombia.id;
                  });
                } catch (_) {
                  // Si no encuentra Colombia, usa el primero
                  setState(() {
                    _colombiaId = state.countries.first.id;
                    _countryController.text = state.countries.first.id;
                    _selectedPhoneCountryId ??= state.countries.first.id;
                  });
                }
              }
            },
          ),
        ],
        child: FixedBottomActionLayout(
          bottomChild: BlocBuilder<AuthBloc, AuthState>(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppSpacing.xxl,
              left: AppSpacing.l,
              right: AppSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Finaliza tu registro - Propietario',
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Estos han sido los datos recopilados de tu cuenta de ${widget.providerName}, completa los datos faltantes para continuar:',
                  style: AppTypography.body4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.l),

                CustomTextField(
                  label: 'Nombre completo',
                  controller: _nameController,
                  enabled: true,
                  labelStyle: AppTypography.body6.copyWith(
                    color: const Color(0xFF2E3949).withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                CustomTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  enabled: false,
                  validator: ValidationUtils.validateEmail,
                  labelStyle: AppTypography.body6.copyWith(
                    color: const Color(0xFF2E3949).withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Sección de país/ID/teléfono integrada directamente
                // igual que _LocationSelector en edit_profile_screen
                BlocBuilder<LocationsCubit, LocationsState>(
                  builder: (context, state) {
                    if (state is LocationsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is! LocationsLoaded) {
                      return const Text('Error cargando países');
                    }

                    final countries = state.countries;

                    // País de residencia: siempre Colombia, disabled
                    final colombiaId = _colombiaId ??
                        (countries.isNotEmpty ? countries.first.id : null);

                    return Column(
                      children: [
                        // País de residencia — siempre Colombia, no editable
                        CountryDropdown(
                          label: 'País de residencia',
                          value: colombiaId,
                          countries: countries,
                          enabled: false,
                          width: double.infinity,
                          onChanged: null,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Identificación
                        IdSelector(
                          idController: _idController,
                          initialIdType: _selectedIdType,
                          onIdTypeChanged: (val) {
                            setState(() => _selectedIdType = val);
                          },
                          errorText: _idErrorText,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Teléfono con selector de país interactivo
                        PhoneInputField(
                          label: 'Número de celular (Opcional)',
                          controller: _phoneController,
                          countries: countries,
                          selectedCountryId:
                              _selectedPhoneCountryId ??
                              (countries.isNotEmpty
                                  ? countries.first.id
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
                  },
                ),

                const KeyboardSpacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
