import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import '../../../../core/widgets/layout/fixed_bottom_action_layout.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/register_steps/personal_data_step.dart';
import '../widgets/register_steps/professional_data_step.dart';
import '../widgets/register_steps/security_step.dart';
import '../widgets/register_steps/owner_method_selection_step.dart';
import '../widgets/register_steps/owner_personal_data_step.dart';

import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/domain/entities/register_params.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import 'package:animal_record/features/auth/presentation/widgets/phone_input_field.dart';
import 'package:uuid/uuid.dart';
import '../widgets/tag_input_widget.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final idController = TextEditingController();
  final phoneController = TextEditingController();
  final professionalCardController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _acceptTerms = false;
  String? _confirmPasswordError;

  List<String> _animalTypes = [];
  List<String> _services = [];

  final GlobalKey<TagInputWidgetState> _animalTypesKey = GlobalKey();
  final GlobalKey<TagInputWidgetState> _servicesKey = GlobalKey();

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  AccessMethod? _selectedAccessMethod;
  String? _phoneErrorText;
  String? _emailErrorText;
  String? _idErrorText;

  List<Widget>? _cachedSteps;
  AccessMethod? _lastAccessMethod;
  String? _lastPhoneErrorText;
  String? _lastEmailErrorText;
  String? _selectedPhoneCountryId;

  String _selectedIdType = 'C.C.';

  List<Widget> get _steps {
    final List<Widget> steps = [];

    if (widget.role == 'PROPIETARIO_MASCOTA') {
      steps.add(
        OwnerMethodSelectionStep(
          emailController: emailController,
          phoneController: phoneController,
          countryController: countryController,
          phoneFocusNode: _phoneFocusNode,
          onMethodChanged: (method) {
            setState(() {
              _selectedAccessMethod = method;
              _cachedSteps = null;
            });
          },
          selectedPhoneCountryId: _selectedPhoneCountryId,
          onPhoneCountryChanged: (value) {
            setState(() => _selectedPhoneCountryId = value);
          },
        ),
      );

      if (_selectedAccessMethod != null) {
        steps.add(
          OwnerPersonalDataStep(
            nameController: nameController,
            emailController: emailController,
            phoneController: phoneController,
            countryController: countryController,
            idController: idController,
            phoneFocusNode: _phoneFocusNode,
            showOptionalEmail: _selectedAccessMethod == AccessMethod.phone,
            showOptionalPhone: _selectedAccessMethod == AccessMethod.email,
            phoneErrorText: _phoneErrorText,
            emailErrorText: _emailErrorText,
            idErrorText: _idErrorText,
            initialIdType: _selectedIdType,
            onIdTypeChanged: (type) {
              _selectedIdType = type;
            },
            selectedPhoneCountryId: _selectedPhoneCountryId,
            onPhoneCountryChanged: (value) {
              setState(() => _selectedPhoneCountryId = value);
            },
          ),
        );
      }
    } else {
      steps.add(
        PersonalDataStep(
          nameController: nameController,
          emailController: emailController,
          countryController: countryController,
          cityController: cityController,
          idController: idController,
          phoneController: phoneController,
          phoneFocusNode: _phoneFocusNode,
          selectedPhoneCountryId: _selectedPhoneCountryId,
          onPhoneCountryChanged: (value) {
            setState(() => _selectedPhoneCountryId = value);
          },
        ),
      );
    }

    if (widget.role == 'VETERINARIO') {
      steps.add(
        ProfessionalDataStep(
          professionalCardController: professionalCardController,
          animalTypes: _animalTypes,
          onAnimalTypesChanged: (types) => setState(() => _animalTypes = types),
          services: _services,
          onServicesChanged: (services) => setState(() => _services = services),
          animalTypesKey: _animalTypesKey,
          servicesKey: _servicesKey,
        ),
      );
    } else if (widget.role == 'LABORATORIO') {}

    steps.add(
      SecurityStep(
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        acceptTerms: _acceptTerms,
        confirmPasswordError: _confirmPasswordError,
        onTermsChanged: (value) {
          setState(() {
            _acceptTerms = value;
          });
        },
      ),
    );

    _cachedSteps = steps;
    return steps;
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void _onConfirmPasswordChanged() {
    final confirm = confirmPasswordController.text;
    final password = passwordController.text;

    if (confirm.isNotEmpty && confirm != password) {
      if (_confirmPasswordError == null) {
        setState(() {
          _confirmPasswordError = 'Las contraseñas no coinciden';
        });
      }
    } else {
      if (_confirmPasswordError != null) {
        setState(() {
          _confirmPasswordError = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    phoneController.addListener(_onPhoneChanged);

    emailController.addListener(_onEmailChanged);

    confirmPasswordController.addListener(_onConfirmPasswordChanged);

    passwordController.addListener(_onConfirmPasswordChanged);

    idController.addListener(_onIdChanged);

    context.read<LocationsCubit>().fetchCountries();
  }

  void _onIdChanged() {
    if (_idErrorText != null) {
      setState(() {
        _idErrorText = null;
      });
    }
  }

  void _onPhoneChanged() {
    if (_phoneErrorText != null) {
      final text = phoneController.text;

      if (text.isEmpty || _isValidPhone(text)) {
        setState(() {
          _phoneErrorText = null;
        });
      }
    }
  }

  void _onEmailChanged() {
    if (_emailErrorText != null) {
      final text = emailController.text;
      if (text.isEmpty || _isValidEmail(text)) {
        setState(() {
          _emailErrorText = null;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.removeListener(_onPhoneChanged);
    emailController.removeListener(_onEmailChanged);
    confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    passwordController.removeListener(_onConfirmPasswordChanged);
    idController.removeListener(_onIdChanged);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    idController.dispose();
    phoneController.dispose();
    professionalCardController.dispose();
    countryController.dispose();
    cityController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (widget.role == 'PROPIETARIO_MASCOTA' && _currentStep == 1) {
      bool hasError = false;

      if (_selectedAccessMethod == AccessMethod.email) {
        if (phoneController.text.isNotEmpty &&
            !_isValidPhone(phoneController.text)) {
          setState(() {
            _phoneErrorText =
                'Introduzca su número de celular en el formato XXX-XXX-XX-XX';
          });
          hasError = true;
        } else if (_phoneErrorText != null) {
          setState(() => _phoneErrorText = null);
        }
      } else if (_selectedAccessMethod == AccessMethod.phone) {
        if (emailController.text.isNotEmpty &&
            !_isValidEmail(emailController.text)) {
          setState(() {
            _emailErrorText =
                'Introduzca una dirección de correo electrónico válida';
          });
          hasError = true;
        } else if (_emailErrorText != null) {
          setState(() => _emailErrorText = null);
        }
      }

      if (hasError) return;

      if (idController.text.isNotEmpty) {
        context.read<AuthBloc>().add(
          CheckIdentificationExists(idController.text),
        );

        return;
      }
    }

    if (!_isStepValid()) {
      ErrorDisplay.showError(
        context,
        'Por favor completa todos los campos requeridos',
      );
      return;
    }

    if (_currentStep == _steps.length - 1) {
      _submitRegistration();
    } else {
      setState(() => _currentStep++);
    }
  }

  String get _roleName {
    switch (widget.role) {
      case 'VETERINARIO':
        return 'Veterinario';
      case 'PROPIETARIO_MASCOTA':
        return 'Propietario';
      case 'ESTUDIANTE':
        return 'Estudiante';
      case 'LABORATORIO':
        return 'Laboratorio';
      default:
        return widget.role;
    }
  }

  int get _totalSteps {
    if (widget.role == 'PROPIETARIO_MASCOTA') {
      return 3;
    } else if (widget.role == 'VETERINARIO') {
      return 3;
    } else {
      return 2;
    }
  }

  bool _isStepValid() {
    final step = _currentStep;
    final steps = _steps;

    if (widget.role == 'PROPIETARIO_MASCOTA') {
      if (step == 0) {
        if (_selectedAccessMethod == AccessMethod.email) {
          return _isValidEmail(emailController.text);
        } else if (_selectedAccessMethod == AccessMethod.phone) {
          return _isValidPhone(phoneController.text);
        }
        return false;
      }
      if (step == 1) {
        return idController.text.isNotEmpty &&
            nameController.text.isNotEmpty &&
            countryController.text.isNotEmpty;
      }
    }

    if (widget.role == 'VETERINARIO') {
      if (step == 0) {
        return nameController.text.isNotEmpty &&
            emailController.text.isNotEmpty &&
            _isValidEmail(emailController.text) &&
            countryController.text.isNotEmpty &&
            idController.text.isNotEmpty &&
            phoneController.text.isNotEmpty;
      }
      if (step == 1) {
        return professionalCardController.text.isNotEmpty &&
            _animalTypes.isNotEmpty &&
            _services.isNotEmpty;
      }
    }

    if (step == steps.length - 1) {
      final isPasswordComplex = _isPasswordValid(passwordController.text);
      final passwordsMatch =
          passwordController.text == confirmPasswordController.text;
      return isPasswordComplex && passwordsMatch && _acceptTerms;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _submitRegistration() {
    _animalTypesKey.currentState?.addPendingTag();
    _servicesKey.currentState?.addPendingTag();

    const uuid = Uuid();
    final String newUserId = uuid.v4();

    String getFieldValue(TextEditingController controller) {
      return controller.text.trim();
    }

    String cellPhone = getFieldValue(phoneController);
    if (cellPhone.isNotEmpty && !cellPhone.startsWith('+')) {
      final state = context.read<LocationsCubit>().state;
      if (state is LocationsLoaded) {
        final countryId = _selectedPhoneCountryId ?? getFieldValue(countryController);
        if (countryId.isNotEmpty) {
          final country = state.countries.cast<CountryEntity>().firstWhere(
            (c) => c.id == countryId,
            orElse: () => state.countries.first,
          );
          cellPhone = '${country.dialCode}$cellPhone'.replaceAll(' ', '');
        }
      }
    }

    context.read<AuthBloc>().add(
      SignUpSubmitted(
        RegisterParams(
          id: newUserId,
          name: getFieldValue(nameController),
          email: getFieldValue(emailController),
          password: getFieldValue(passwordController),
          identificationType: widget.role == 'PROPIETARIO_MASCOTA'
              ? _selectedIdType.replaceAll('.', '').toUpperCase()
              : 'CC',
          identificationNumber: getFieldValue(idController),
          cellPhone: cellPhone,
          country: '',
          countryId: _selectedPhoneCountryId ?? getFieldValue(countryController),
          city: widget.role == 'PROPIETARIO_MASCOTA'
              ? ''
              : getFieldValue(cityController),
          address: '',
          roles: [widget.role],
          professionalCard: widget.role == 'VETERINARIO'
              ? getFieldValue(professionalCardController)
              : '',
          animalTypes: widget.role == 'VETERINARIO' ? _animalTypes : [],
          services: widget.role == 'VETERINARIO' ? _services : [],
          isHomeDelivery: widget.role == 'VETERINARIO' ? true : false,
          authMethod: _selectedAccessMethod == AccessMethod.phone
              ? 'PHONE'
              : 'EMAIL',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;

    return AuthFormContainer(
      showLogo: false,
      title: 'Tu cuenta AnimalRecord - $_roleName',
      subtitle: _currentStep < steps.length - 1
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        widget.role == 'PROPIETARIO_MASCOTA' &&
                            _currentStep == 0
                        ? 'Ingreso '
                        : 'Datos personales ',
                    style: AppTypography.body4,
                  ),
                  TextSpan(
                    text: '- ${_currentStep + 1} de $_totalSteps',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                  ),
                ],
              ),
            )
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Seguridad ', style: AppTypography.body4),
                  TextSpan(
                    text: '- ${_currentStep + 1} de $_totalSteps',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                  ),
                ],
              ),
            ),
      onBack: _currentStep > 0
          ? () => setState(() => _currentStep--)
          : () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
      addInternalPadding: false,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ErrorDisplay.showSuccess(
              context,
              'Registro exitoso. Por favor inicia sesión.',
            );
            Navigator.pushReplacementNamed(context, '/');
          } else if (state is AuthError) {
            ErrorDisplay.showError(context, state.message);
          } else if (state is IdentificationCheckResult) {
            if (state.exists) {
              setState(() {
                _idErrorText =
                    'Parece que ya tienes una cuenta. Intenta iniciar sesión o restablecer tu contraseña.';
              });
            } else {
              setState(() => _currentStep++);
            }
          }
        },
        child: BlocBuilder<LocationsCubit, LocationsState>(
          builder: (context, locState) {
            if (locState is LocationsLoaded && _selectedPhoneCountryId == null) {
              final colombia = locState.countries.cast<CountryEntity>().firstWhere(
                    (c) => c.name.toLowerCase().contains('colombia'),
                    orElse: () => locState.countries.first,
                  );
              _selectedPhoneCountryId = colombia.id;
            }
            return FixedBottomActionLayout(
              bottomChild: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AnimatedBuilder(
                    animation: Listenable.merge(_getStepListenables()),
                    builder: (context, _) {
                      final buttonText = _currentStep == steps.length - 1
                          ? 'Crear cuenta'
                          : 'Continuar';

                      final isValid = _isStepValid();

                      return CustomButton(
                        text: buttonText,
                        isLoading: state is AuthLoading,
                        onPressed: state is AuthLoading || !isValid
                            ? null
                            : _nextStep,
                      );
                    },
                  );
                },
              ),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xl,
                    right: AppSpacing.l,
                    left: AppSpacing.l,
                  ),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(_currentStep),
                          child: steps[_currentStep],
                        ),
                      ),
                      const KeyboardSpacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Listenable> _getStepListenables() {
    final step = _currentStep;
    final steps = _steps;

    if (widget.role == 'PROPIETARIO_MASCOTA') {
      if (step == 0) {
        return [emailController, phoneController];
      }
      if (step == 1) {
        return [
          nameController,
          idController,
          countryController,
          emailController,
          phoneController,
        ];
      }
    }

    if (widget.role == 'VETERINARIO') {
      if (step == 0) {
        return [
          nameController,
          emailController,
          countryController,
          idController,
          phoneController,
        ];
      }
      if (step == 1) {
        return [professionalCardController];
      }
    }

    if (step == steps.length - 1) {
      return [passwordController, confirmPasswordController];
    }

    return [];
  }
}
