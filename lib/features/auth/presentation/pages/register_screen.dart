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

import 'package:uuid/uuid.dart';
import '../widgets/tag_input_widget.dart';
import 'package:animal_record/core/utils/error_display.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Controladores
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final idController = TextEditingController();
  final phoneController = TextEditingController();
  final professionalCardController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();

  bool _acceptTerms = false;
  String? _confirmPasswordError;

  // State for tag inputs
  List<String> _animalTypes = [];
  List<String> _services = [];

  // GlobalKeys to access TagInputWidget state
  final GlobalKey<TagInputWidgetState> _animalTypesKey = GlobalKey();
  final GlobalKey<TagInputWidgetState> _servicesKey = GlobalKey();

  // GlobalKey to access VerificationStep state

  bool _isValidPhone(String phone) {
    // Basic phone validation (at least 10 digits)
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  // Owner-specific state
  AccessMethod? _selectedAccessMethod;
  String? _phoneErrorText;
  String? _emailErrorText;
  String? _idErrorText;

  // Cache for steps to avoid rebuilding on every setState
  List<Widget>? _cachedSteps;
  AccessMethod? _lastAccessMethod;
  String? _lastPhoneErrorText;
  String? _lastEmailErrorText;
  String _selectedIdType = 'C.C.';

  // Definición dinámica de pasos según el rol
  List<Widget> get _steps {
    // Return cached steps if nothing changed
    // Note: For SecurityStep we manage state in the parent, so we might need to
    // rebuild it more often or rely on its own state update from parent.
    // However, the terms checkbox triggers setState in parent, which rebuilds _steps.

    final List<Widget> steps = [];

    // PROPIETARIO: First step is method selection
    if (widget.role == 'PROPIETARIO_MASCOTA') {
      steps.add(
        OwnerMethodSelectionStep(
          emailController: emailController,
          phoneController: phoneController,
          countryController: countryController,
          onMethodChanged: (method) {
            setState(() {
              _selectedAccessMethod = method;
              _cachedSteps = null; // Invalidate cache when method changes
            });
          },
        ),
      );

      // PROPIETARIO: Owner-specific personal data step
      if (_selectedAccessMethod != null) {
        steps.add(
          OwnerPersonalDataStep(
            nameController: nameController,
            emailController: emailController,
            phoneController: phoneController,
            countryController: countryController,
            idController: idController,
            showOptionalEmail: _selectedAccessMethod == AccessMethod.phone,
            showOptionalPhone: _selectedAccessMethod == AccessMethod.email,
            phoneErrorText: _phoneErrorText,
            emailErrorText: _emailErrorText,
            idErrorText: _idErrorText,
            initialIdType: _selectedIdType,
            onIdTypeChanged: (type) {
              _selectedIdType = type;
            },
          ),
        );
      }
    } else {
      // Other roles: Standard personal data step
      steps.add(
        PersonalDataStep(
          nameController: nameController,
          emailController: emailController,
          countryController: countryController,
          cityController: cityController,
          idController: idController,
          phoneController: phoneController,
        ),
      );
    }

    // VETERINARIO: Professional data step
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
    } else if (widget.role == 'LABORATORIO') {
      // TODO: Añadir paso específico para laboratorio si es necesario
    }

    // All roles: Security/Password step
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
    // 8+ chars, upper, lower, number, special
    return password.length >= 8 &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void _onConfirmPasswordChanged() {
    final confirm = confirmPasswordController.text;
    final password = passwordController.text;

    // Check mismatch: if confirm is not empty AND differs from password
    // OR if we already have an error (to see if it's fixed)
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
    // Add listeners removed to prevent crash. Validation handled by ValueListenableBuilder.

    // Add listener to phone controller for immediate feedback on error state
    phoneController.addListener(_onPhoneChanged);
    // Add listener for email controller
    emailController.addListener(_onEmailChanged);
    // Add listener for confirm password (inline validation)
    confirmPasswordController.addListener(_onConfirmPasswordChanged);
    // Add listener for password (to clear confirm error if password matches again)
    passwordController.addListener(_onConfirmPasswordChanged);
    // Add listener for ID controller
    idController.addListener(_onIdChanged);
  }

  void _onIdChanged() {
    if (_idErrorText != null) {
      setState(() {
        _idErrorText = null;
      });
    }
  }

  void _onPhoneChanged() {
    // Only check if there is an error current displayed
    if (_phoneErrorText != null) {
      final text = phoneController.text;
      // Clear error if empty or valid (>= 10 digits)
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
    // Remove listener before disposing
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
    super.dispose();
  }

  void _nextStep() {
    // Validate inline errors for optional fields (specifically Phone/Email) on submit
    if (widget.role == 'PROPIETARIO_MASCOTA' && _currentStep == 1) {
      bool hasError = false;

      if (_selectedAccessMethod == AccessMethod.email) {
        // Validate optional phone if entered
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
        // Validate optional email if entered
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

      // Check if identification number already exists
      if (idController.text.isNotEmpty) {
        context.read<AuthBloc>().add(
          CheckIdentificationExists(idController.text),
        );
        // The result will be handled in BlocListener below
        // If exists, we'll show error and return
        // If doesn't exist, we'll proceed to next step
        return;
      }
    }

    // Validate current step before proceeding
    if (!_isStepValid()) {
      ErrorDisplay.showError(
        context,
        'Por favor completa todos los campos requeridos',
      );
      return;
    }

    // Si estamos en el último paso (SecurityStep), crear el usuario
    if (_currentStep == _steps.length - 1) {
      _submitRegistration();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  // Helper to get readable role name
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

  // Helper to get total expected steps for this role
  int get _totalSteps {
    if (widget.role == 'PROPIETARIO_MASCOTA') {
      return 3; // Method selection + Personal data + Security
    } else if (widget.role == 'VETERINARIO') {
      return 3; // Personal data + Professional data + Security
    } else {
      return 2; // Personal data + Security (default)
    }
  }

  bool _isStepValid() {
    final step = _currentStep;
    final steps = _steps;

    // Validation for Owner Method Selection
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
        // As per user request: "el button solo se debe activar cuando el campo identificacion este lleno"
        // and "el pais debe ir deshabilitado" (already handled in step widget).
        // Standard personal data fields (Name/Country) might still be required for a valid user,
        // but the button's activation is primarily driven by ID in this specific request.
        return idController.text.isNotEmpty &&
            nameController.text.isNotEmpty &&
            countryController.text.isNotEmpty;
      }
    }

    // Validation for Veterinario/Other Roles
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

    // Common steps (Security)
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
    // Add any pending tags before submitting
    _animalTypesKey.currentState?.addPendingTag();
    _servicesKey.currentState?.addPendingTag();

    const uuid = Uuid();
    final String newUserId = uuid.v4();

    // Helper to get non-empty string or empty string (backend accepts empty now)
    String getFieldValue(TextEditingController controller) {
      return controller.text.trim();
    }

    String cellPhone = getFieldValue(phoneController);

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
          country: '', // populated by backend based on countryId
          countryId: getFieldValue(countryController), // stores country ID
          city: widget.role == 'PROPIETARIO_MASCOTA'
              ? ''
              : getFieldValue(cityController),
          address:
              '', // Address is optional and not collected during registration
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
      onBack: _currentStep > 0
          ? () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentStep--);
            }
          : () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Usuario creado exitosamente
            // Usuario creado exitosamente
            ErrorDisplay.showSuccess(
              context,
              'Registro exitoso. Por favor inicia sesión.',
            );
            Navigator.pushReplacementNamed(context, '/'); // Go to login
          } else if (state is AuthError) {
            ErrorDisplay.showError(context, state.message);
          } else if (state is IdentificationCheckResult) {
            if (state.exists) {
              // El usuario ya está registrado
              setState(() {
                _idErrorText =
                    'Este número de documento ya está registrado. Por favor inicia sesión.';
              });
            } else {
              // El usuario no existe, proceder al siguiente paso
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _currentStep++);
            }
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xxl,
                right: AppSpacing.l,
                left: AppSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: AppSpacing.registerTitleHeight,
                    child: Text(
                      'Tu cuenta AnimalRecord - $_roleName',
                      style: AppTypography.heading1,
                    ),
                  ),
                  if (_currentStep < steps.length - 1)
                    SizedBox(
                      height: AppSpacing.registerSubtitleHeight,
                      child: Text.rich(
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
                      ),
                    )
                  else
                    SizedBox(
                      height: AppSpacing.registerSubtitleHeight,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Seguridad ',
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
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: FixedBottomActionLayout(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xl,
                    right: AppSpacing.l,
                    left: AppSpacing.l,
                  ),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: steps.map((step) {
                      return SingleChildScrollView(child: step);
                    }).toList(),
                  ),
                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Listenable> _getStepListenables() {
    final step = _currentStep;
    final steps = _steps;

    // Common listenables for all steps (if any global state affects validation)
    // For now, we return specific controllers based on the step logic in _isStepValid

    if (widget.role == 'PROPIETARIO_MASCOTA') {
      if (step == 0) {
        // Method selection step: listen to email and phone controllers
        // The validation depends on _selectedAccessMethod which is state,
        // but the input content is in controllers.
        // We also need to listen to the selection change, but that triggers setState,
        // so the widget rebuilds anyway.
        return [emailController, phoneController];
      }
      if (step == 1) {
        // Personal data step
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
        // First step for Vet
        return [
          nameController,
          emailController,
          countryController,
          idController,
          phoneController,
        ];
      }
      if (step == 1) {
        // Professional data step
        // These are more complex because they might not be just text controllers
        // _animalTypes and _services are lists updated via setState, so build is triggered.
        // professionalCardController is a text controller.
        return [professionalCardController];
      }
    }

    // Security step (last)
    if (step == steps.length - 1) {
      // Need to listen to both password fields. Terms checked via setState rebuild.
      return [passwordController, confirmPasswordController];
    }

    return [];
  }
}
