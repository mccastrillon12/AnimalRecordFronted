import 'package:flutter/material.dart';
import '../widgets/auth_form_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/register_steps/personal_data_step.dart';
import '../widgets/register_steps/professional_data_step.dart';
import '../widgets/register_steps/security_step.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    idController.dispose();
    phoneController.dispose();
    professionalCardController.dispose();
    super.dispose();
  }

  // Definición dinámica de pasos según el rol
  List<Widget> get _steps {
    final List<Widget> steps = [
      PersonalDataStep(
        nameController: nameController,
        emailController: emailController,
      ),
    ];

    if (widget.role == 'VETERINARIO') {
      steps.add(
        ProfessionalDataStep(
          professionalCardController: professionalCardController,
          idController: idController,
          phoneController: phoneController,
        ),
      );
    } else if (widget.role == 'LABORATORIO') {
      // TODO: Añadir paso específico para laboratorio si es necesario
    }

    steps.add(SecurityStep(passwordController: passwordController));
    return steps;
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  void _submitRegistration() {
    const uuid = Uuid();
    final String newUserId = uuid.v4();

    context.read<AuthBloc>().add(
      SignUpSubmitted({
        'id': newUserId,
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'identificationType': 'CC',
        'identificationNumber': idController.text,
        'country': 'Colombia',
        'city': 'Medellín',
        'cellPhone': phoneController.text,
        'professionalCard': professionalCardController.text,
        'roles': [widget.role],
        'animalTypes': ['Dogs', 'Cats'],
        'services': ['General Consultation'],
        'isHomeDelivery': true,
      }),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu cuenta AnimalRecord - ${widget.role.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Datos - ${_currentStep + 1} de ${steps.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 450,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: steps,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 40,
                top: 16,
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return CustomButton(
                    text: _currentStep == steps.length - 1
                        ? 'Crear cuenta'
                        : 'Continuar',
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
