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
import 'package:animal_record/features/auth/presentation/cubit/register_cubit.dart';
import 'package:animal_record/features/auth/presentation/cubit/register_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_cubit.dart';
import 'package:animal_record/features/locations/presentation/cubit/locations_state.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import 'package:uuid/uuid.dart';
import '../widgets/tag_input_widget.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/utils/keyboard_spacer.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class RegisterScreen extends StatelessWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(role: role),
      child: const RegisterScreenView(),
    );
  }
}

class RegisterScreenView extends StatefulWidget {
  const RegisterScreenView({super.key});

  @override
  State<RegisterScreenView> createState() => _RegisterScreenViewState();
}

class _RegisterScreenViewState extends State<RegisterScreenView> {
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<TagInputWidgetState> _animalTypesKey = GlobalKey();
  final GlobalKey<TagInputWidgetState> _servicesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  List<Widget> _buildSteps(RegisterState state) {
    final List<Widget> steps = [];

    if (state.role == 'PROPIETARIO_MASCOTA') {
      steps.add(
        OwnerMethodSelectionStep(
          phoneFocusNode: _phoneFocusNode,
        ),
      );

      if (state.accessMethod != null) {
        steps.add(
          OwnerPersonalDataStep(
            phoneFocusNode: _phoneFocusNode,
            showOptionalEmail: state.accessMethod == AccessMethod.phone,
            showOptionalPhone: state.accessMethod == AccessMethod.email,
          ),
        );
      }
    } else {
      steps.add(
        PersonalDataStep(
          phoneFocusNode: _phoneFocusNode,
        ),
      );
    }

    if (state.role == 'VETERINARIO') {
      steps.add(
        ProfessionalDataStep(
          animalTypesKey: _animalTypesKey,
          servicesKey: _servicesKey,
        ),
      );
    } else if (state.role == 'LABORATORIO') {}

    steps.add(const SecurityStep());

    return steps;
  }

  String _getNormalizedPhone(BuildContext context, RegisterState state) {
    String cellPhone = state.phone.value;
    if (cellPhone.isNotEmpty && !cellPhone.startsWith('+')) {
      final locState = context.read<LocationsCubit>().state;
      if (locState is LocationsLoaded) {
        final phoneCountryId = state.phoneCountryId.isNotEmpty
            ? state.phoneCountryId
            : state.countryId;
        
        CountryEntity? country;
        if (phoneCountryId.isNotEmpty) {
          country = locState.countries.cast<CountryEntity>().firstWhere(
            (c) => c.id == phoneCountryId,
            orElse: () => locState.countries.first,
          );
        } else if (locState.countries.isNotEmpty) {
          // Default to the first loaded country (e.g., Colombia) if neither ID is filled yet
          country = locState.countries.first;
        }

        if (country != null) {
          cellPhone = '${country.dialCode}$cellPhone'.replaceAll(' ', '');
        }
      }
    }
    return cellPhone;
  }

  void _nextStep(RegisterCubit cubit, RegisterState state) {
    if (!state.isCurrentStepValid) {
      ErrorDisplay.showError(
        context,
        'Por favor completa correctamente todos los campos requeridos',
      );
      return;
    }

    final normalizedPhone = _getNormalizedPhone(context, state);
    Map<String, dynamic> dataToCheck = {};
    if (state.role == 'PROPIETARIO_MASCOTA') {
      if (state.currentStep == 0) {
        if (state.accessMethod == AccessMethod.email && state.email.value.isNotEmpty) {
          dataToCheck['email'] = state.email.value;
        } else if (state.accessMethod == AccessMethod.phone && state.phone.value.isNotEmpty) {
          dataToCheck['cellPhone'] = normalizedPhone;
        }
      } else if (state.currentStep == 1) {
        if (state.identificationNumber.value.isNotEmpty) {
          dataToCheck['identificationNumber'] = state.identificationNumber.value;
        }
        if (state.accessMethod == AccessMethod.phone && state.email.value.isNotEmpty) {
          dataToCheck['email'] = state.email.value;
        } else if (state.accessMethod == AccessMethod.email && state.phone.value.isNotEmpty) {
          dataToCheck['cellPhone'] = normalizedPhone;
        }
      }
    } else {
       if (state.currentStep == 0) {
          if (state.identificationNumber.value.isNotEmpty) {
            dataToCheck['identificationNumber'] = state.identificationNumber.value;
          }
          if (state.email.value.isNotEmpty) {
            dataToCheck['email'] = state.email.value;
          }
          if (state.phone.value.isNotEmpty) {
            dataToCheck['cellPhone'] = normalizedPhone;
          }
       }
    }

    if (dataToCheck.isNotEmpty) {
      context.read<AuthBloc>().add(CheckAvailabilityRequested(dataToCheck));
      return;
    }

    if (state.currentStep == state.totalSteps - 1) {
      _submitRegistration(cubit, state);
    } else {
      cubit.nextStep();
    }
  }

  void _submitRegistration(RegisterCubit cubit, RegisterState state) {
    _animalTypesKey.currentState?.addPendingTag();
    _servicesKey.currentState?.addPendingTag();

    const uuid = Uuid();
    final String newUserId = uuid.v4();

    final String cellPhone = _getNormalizedPhone(context, state);

    context.read<AuthBloc>().add(
      SignUpSubmitted(
        cubit.buildParams(userId: newUserId, finalPhone: cellPhone),
      ),
    );
  }

  String _getRoleName(String rawRole) {
    switch (rawRole) {
      case 'VETERINARIO':
        return 'Veterinario';
      case 'PROPIETARIO_MASCOTA':
        return 'Propietario';
      case 'ESTUDIANTE':
        return 'Estudiante';
      case 'LABORATORIO':
        return 'Laboratorio';
      default:
        return rawRole;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterCubit>();

    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final steps = _buildSteps(state);
        // Ensure index boundary logic
        final safeStep = state.currentStep < steps.length ? state.currentStep : (steps.isNotEmpty ? steps.length - 1 : 0);
        final currentStepWidget = steps.isNotEmpty ? steps[safeStep] : const SizedBox.shrink();
        
        return AuthFormContainer(
          showLogo: false,
          title: 'Tu cuenta AnimalRecord - ${_getRoleName(state.role)}',
          subtitle: safeStep < state.totalSteps - 1
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: state.role == 'PROPIETARIO_MASCOTA' && safeStep == 0
                            ? 'Ingreso '
                            : 'Datos personales ',
                        style: AppTypography.body4,
                      ),
                      TextSpan(
                        text: '- ${safeStep + 1} de ${state.totalSteps}',
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
                        text: '- ${safeStep + 1} de ${state.totalSteps}',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      ),
                    ],
                  ),
                ),
          onBack: safeStep > 0
              ? () => cubit.previousStep()
              : () => Navigator.pop(context),
          onCancel: () => Navigator.pop(context),
          addInternalPadding: false,
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthSuccess && 
                  (ModalRoute.of(context)?.isCurrent ?? false)) {
                ErrorDisplay.showSuccess(
                  context,
                  'Registro exitoso. Por favor inicia sesión.',
                );
                Navigator.pushReplacementNamed(context, '/');
              } else if (authState is AuthError) {
                ErrorDisplay.showError(context, authState.message);
              } else if (authState is IdentificationCheckResult) {
                if (authState.exists) {
                   cubit.idErrorChanged(true);
                  ErrorDisplay.showError(
                    context,
                    'Parece que ya tienes una cuenta con esta identificación. Intenta iniciar sesión.',
                  );
                } else {
                  cubit.nextStep();
                }
              } else if (authState is AvailabilityCheckResult) {
                final status = authState.availabilityStatus;
                String? errorMessage;
                
                if (status.containsKey('identificationNumber') && status['identificationNumber'] == false) {
                  cubit.idErrorChanged(true);
                  errorMessage = 'Parece que ya tienes una cuenta con esta identificación. Intenta iniciar sesión.';
                } 
                
                if (status.containsKey('email') && status['email'] == false) {
                  cubit.emailErrorChanged(true);
                  errorMessage = 'Parece que ya tienes una cuenta con este correo electrónico. Intenta iniciar sesión.';
                } 
                
                if (status.containsKey('cellPhone') && status['cellPhone'] == false) {
                   cubit.phoneErrorChanged(true);
                   errorMessage = 'Parece que ya tienes una cuenta con este número celular. Intenta iniciar sesión.';
                }

                if (errorMessage != null) {
                  ErrorDisplay.showError(context, errorMessage);
                } else {
                  cubit.nextStep();
                }
              }
            },
            child: FixedBottomActionLayout(
              bottomChild: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final buttonText = safeStep == state.totalSteps - 1 ? 'Crear cuenta' : 'Continuar';
                  final isValid = state.isCurrentStepValid;

                  return CustomButton(
                    text: buttonText,
                    isLoading: authState is AuthLoading,
                    onPressed: (authState is AuthLoading || !isValid)
                        ? null
                        : () => _nextStep(cubit, state),
                  );
                },
              ),
              child: KeyboardActions(
                config: KeyboardActionsConfig(
                  keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                  keyboardBarColor: AppColors.iosKeyboardGray,
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
                          key: ValueKey(safeStep),
                          child: currentStepWidget,
                        ),
                      ),
                      const KeyboardSpacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
