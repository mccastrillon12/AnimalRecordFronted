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
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:animal_record/core/utils/validation_utils.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
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

  String? _selectedPhoneCountryId;
  String _selectedIdType = 'C.C.';
  String? _idErrorText;
  String? _phoneErrorText;
  bool _isNavigating = false;
  final FocusNode _phoneFocusNode = FocusNode();

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
    _phoneFocusNode.dispose();
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

    String phoneWithDialCode = _phoneController.text.trim();

    String idType = 'CC';
    if (_selectedIdType == 'C.E.') idType = 'CE';
    if (_selectedIdType == 'Pasaporte') idType = 'PAS';

    final Map<String, dynamic> data = {
      'preAuthToken': widget.preAuthToken,
      'name': _nameController.text.trim(),
      'identificationNumber': _idController.text.trim(),
      'identificationType': idType,
      'cellPhone': _phoneController.text.trim().isEmpty
          ? ""
          : phoneWithDialCode,
      'country': _countryController.text,
      'city': '',
      'roles': ['PROPIETARIO_MASCOTA'],
    };

    context.read<AuthBloc>().add(
          SocialRegisterSubmitted(
            data,
            nameToUpdate: _nameController.text.trim(),
          ),
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
              if (state is LocationsLoaded) {
                if (_countryController.text.isEmpty &&
                    state.countries.isNotEmpty) {
                  final colombia = state.countries
                      .cast<CountryEntity>()
                      .firstWhere(
                        (c) => c.name.toLowerCase().contains('colombia'),
                        orElse: () => state.countries.first,
                      );
                  setState(() {
                    _countryController.text = colombia.id;
                    _selectedPhoneCountryId = colombia.id;
                  });
                }
              }
            },
          ),
        ],
        child: KeyboardActions(
          config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: const Color(0xFFD1D5DF),
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _phoneFocusNode,
                displayArrows: false,
                displayDoneButton: false,
                toolbarButtons: [
                  (node) {
                    return GestureDetector(
                      onTap: () => node.unfocus(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          "Aceptar",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                ],
              ),
            ],
          ),
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

                  _CountrySelectionSection(phoneFocusNode: _phoneFocusNode),
                  const KeyboardSpacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountrySelectionSection extends StatefulWidget {
  final FocusNode phoneFocusNode;
  const _CountrySelectionSection({required this.phoneFocusNode});

  @override
  State<_CountrySelectionSection> createState() =>
      _CountrySelectionSectionState();
}

class _CountrySelectionSectionState extends State<_CountrySelectionSection> {
  _SocialRegisterCompletionScreenState? get parent =>
      context.findAncestorStateOfType<_SocialRegisterCompletionScreenState>();

  @override
  Widget build(BuildContext context) {
    if (parent == null) return const SizedBox.shrink();

    return BlocBuilder<LocationsCubit, LocationsState>(
      builder: (context, state) {
        if (state is LocationsLoaded) {
          return Column(
            children: [
              CountryDropdown(
                label: 'País de residencia',
                value: parent!._countryController.text.isEmpty
                    ? (state.countries.isNotEmpty
                          ? state.countries.first.id
                          : null)
                    : parent!._countryController.text,
                countries: state.countries,
                enabled: false,
                width: double.infinity,
                onChanged: (val) {
                  if (val != null) {
                    parent!.setState(() {
                      parent!._countryController.text = val;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.m),
              IdSelector(
                idController: parent!._idController,
                initialIdType: parent!._selectedIdType,
                onIdTypeChanged: (val) {
                  parent!.setState(() => parent!._selectedIdType = val);
                },
                errorText: parent!._idErrorText,
              ),
              const SizedBox(height: AppSpacing.m),
              PhoneInputField(
                label: 'Número de celular (Opcional)',
                controller: parent!._phoneController,
                focusNode: widget.phoneFocusNode,
                countries: state.countries,
                selectedCountryId:
                    parent!._selectedPhoneCountryId ??
                    (state.countries.isNotEmpty
                        ? state.countries.first.id
                        : null),
                onCountryChanged: (val) {
                  parent!.setState(() => parent!._selectedPhoneCountryId = val);
                },
                onSubmitted: (_) => parent?._onSubmit(),
                maxLength: 15,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: parent!._phoneErrorText,
              ),
            ],
          );
        } else if (state is LocationsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Text('Error cargando países');
        }
      },
    );
  }
}
