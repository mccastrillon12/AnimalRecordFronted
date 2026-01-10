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
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/domain/entities/register_params.dart';
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
      SignUpSubmitted(
        RegisterParams(
          id: newUserId,
          name: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          identificationType: 'CC',
          identificationNumber: idController.text,
          country: 'Colombia',
          city: 'Medellín',
          cellPhone: phoneController.text,
          professionalCard: professionalCardController.text,
          roles: [widget.role],
          animalTypes: const ['Dogs', 'Cats'],
          services: const ['General Consultation'],
          isHomeDelivery: true,
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
                        'Tu cuenta AnimalRecord - ${widget.role.toLowerCase()}',
                        style: AppTypography.heading1,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.registerSubtitleHeight,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Datos personales ',
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

                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: SizedBox(
                        height: 450,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: steps,
                        ),
                      ),
                    ),
                  ],
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
