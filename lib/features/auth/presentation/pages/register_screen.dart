import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import '../widgets/register_steps/personal_data_step.dart';
import '../widgets/register_steps/professional_data_step.dart';
import '../widgets/register_steps/security_step.dart';
import '../widgets/register_steps/owner_method_selection_step.dart';
import '../widgets/register_steps/owner_personal_data_step.dart';
import '../widgets/register_steps/verification_step.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/domain/entities/register_params.dart';
import 'package:animal_record/features/auth/domain/entities/verify_code_params.dart';
import 'package:uuid/uuid.dart';
import '../widgets/tag_input_widget.dart';

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
  final idController = TextEditingController();
  final phoneController = TextEditingController();
  final professionalCardController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();

  // State for tag inputs
  List<String> _animalTypes = [];
  List<String> _services = [];

  // GlobalKeys to access TagInputWidget state
  final GlobalKey<TagInputWidgetState> _animalTypesKey = GlobalKey();
  final GlobalKey<TagInputWidgetState> _servicesKey = GlobalKey();

  // GlobalKey to access VerificationStep state
  final GlobalKey<VerificationStepState> _verificationKey = GlobalKey();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    idController.dispose();
    phoneController.dispose();
    professionalCardController.dispose();
    countryController.dispose();
    cityController.dispose();
    super.dispose();
  }

  // Owner-specific state
  AccessMethod? _selectedAccessMethod;

  // Cache for steps to avoid rebuilding on every setState
  List<Widget>? _cachedSteps;
  AccessMethod? _lastAccessMethod;

  // Definición dinámica de pasos según el rol
  List<Widget> get _steps {
    // Return cached steps if nothing changed
    if (_cachedSteps != null && _lastAccessMethod == _selectedAccessMethod) {
      return _cachedSteps!;
    }

    _lastAccessMethod = _selectedAccessMethod;
    final List<Widget> steps = [];

    // PROPIETARIO: First step is method selection
    if (widget.role == 'PROPIETARIO_MASCOTA') {
      steps.add(
        OwnerMethodSelectionStep(
          emailController: emailController,
          phoneController: phoneController,
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
            selectedMethod: _selectedAccessMethod!,
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
    steps.add(SecurityStep(passwordController: passwordController));

    // All roles: Verification step
    steps.add(
      VerificationStep(
        key: _verificationKey,
        email: emailController.text,
        phoneNumber: phoneController.text,
        onResendCode: _resendVerificationCode,
      ),
    );

    _cachedSteps = steps;
    return steps;
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

  void _nextStep() {
    // Si estamos en el penúltimo paso (SecurityStep), crear el usuario
    if (_currentStep == _steps.length - 2) {
      _submitRegistration();
    } else if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // En el último paso (verificación), verificar el código
      _verifyCode();
    }
  }

  void _verifyCode() {
    final code = _verificationKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código completo de 5 dígitos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyCodeSubmitted(
        VerifyCodeParams(email: emailController.text, code: code),
      ),
    );
  }

  void _resendVerificationCode() {
    // TODO: Implementar reenvío de código si el backend lo soporta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado exitosamente')),
    );
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

    context.read<AuthBloc>().add(
      SignUpSubmitted(
        RegisterParams(
          id: newUserId,
          name: getFieldValue(nameController),
          email: getFieldValue(emailController),
          password: getFieldValue(passwordController),
          identificationType: widget.role == 'PROPIETARIO_MASCOTA'
              ? 'CC'
              : 'CC',
          identificationNumber: getFieldValue(idController),
          cellPhone: getFieldValue(phoneController),
          country: getFieldValue(countryController),
          city: widget.role == 'PROPIETARIO_MASCOTA'
              ? ''
              : getFieldValue(cityController),
          roles: [widget.role],
          professionalCard: widget.role == 'VETERINARIO'
              ? getFieldValue(professionalCardController)
              : '',
          animalTypes: widget.role == 'VETERINARIO' ? _animalTypes : [],
          services: widget.role == 'VETERINARIO' ? _services : [],
          isHomeDelivery: widget.role == 'VETERINARIO' ? true : false,
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
            // Usuario creado exitosamente, avanzar a verificación
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Revisa tu correo para el código de verificación',
                ),
              ),
            );
            // Avanzar a la pantalla de verificación
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            setState(() => _currentStep++);
          } else if (state is VerificationSuccess) {
            // Código verificado exitosamente, registro completo
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('¡Registro exitoso!')));
            Navigator.pushReplacementNamed(context, '/');
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
                            text: '- ${_currentStep + 1} de ${steps.length}',
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
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom: AppSpacing.xxl,
                top: AppSpacing.m,
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final buttonText = _currentStep == steps.length - 1
                      ? 'Verificar'
                      : _currentStep == steps.length - 2
                      ? 'Crear cuenta'
                      : 'Continuar';
                  return CustomButton(
                    text: buttonText,
                    isLoading: state is AuthLoading,
                    onPressed: _nextStep,
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
