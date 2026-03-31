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
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:animal_record/core/constants/app_strings.dart';
import 'welcome_social_page.dart';
import '../cubit/social_register_cubit.dart';
import '../cubit/social_register_state.dart';

class SocialRegisterCompletionScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SocialRegisterCubit(name: name, email: email),
      child: _SocialRegisterCompletionView(
        name: name,
        email: email,
        preAuthToken: preAuthToken,
        providerName: providerName,
      ),
    );
  }
}

class _SocialRegisterCompletionView extends StatefulWidget {
  final String name;
  final String email;
  final String preAuthToken;
  final String providerName;

  const _SocialRegisterCompletionView({
    required this.name,
    required this.email,
    required this.preAuthToken,
    required this.providerName,
  });

  @override
  State<_SocialRegisterCompletionView> createState() =>
      _SocialRegisterCompletionViewState();
}

class _SocialRegisterCompletionViewState
    extends State<_SocialRegisterCompletionView> {
  final FocusNode _phoneFocusNode = FocusNode();
  String? _colombiaId;
  bool _isNavigating = false;

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

  void _onSubmit(SocialRegisterCubit cubit) {
    // Validar existencia de la cédula primero
    final state = cubit.state;
    context.read<AuthBloc>().add(
          CheckIdentificationExists(state.identificationNumber.value),
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
              } else if (state is IdentificationCheckResult) {
                if (state.exists) {
                  ErrorDisplay.showError(
                    context,
                    'Parece que ya tienes una cuenta con esta identificación. Intenta iniciar sesión.',
                  );
                } else {
                  // Cédula válida y nueva, enviar el registro final
                  final locState = context.read<LocationsCubit>().state;
                  final cubit = context.read<SocialRegisterCubit>();
                  final regState = cubit.state;

                  String prefix = '';
                  String countryToSend = _colombiaId ?? '';

                  if (locState is LocationsLoaded) {
                    final pId = regState.phoneCountryId;
                    if (pId.isNotEmpty) {
                      try {
                        final phoneCountry = locState.countries
                            .cast<CountryEntity>()
                            .firstWhere((c) => c.id == pId);
                        prefix = phoneCountry.dialCode;
                        countryToSend = pId;
                      } catch (_) {}
                    }
                  }

                  final payload = cubit.buildPayload(
                    preAuthToken: widget.preAuthToken,
                    countryToSend: countryToSend,
                    countryPrefix: prefix,
                  );

                  context.read<AuthBloc>().add(
                    SocialRegisterSubmitted(
                      payload,
                      nameToUpdate: regState.name.value,
                    ),
                  );
                }
              }
            },
          ),
          BlocListener<LocationsCubit, LocationsState>(
            listener: (context, state) {
              if (state is LocationsLoaded && state.countries.isNotEmpty) {
                try {
                  final colombia = state.countries
                      .cast<CountryEntity>()
                      .firstWhere(
                        (c) =>
                            c.dialCode == '+57' ||
                            c.name.toLowerCase().contains('colombia'),
                      );
                  if (mounted) {
                    setState(() => _colombiaId = colombia.id);
                    final cubit = context.read<SocialRegisterCubit>();
                    if (cubit.state.phoneCountryId.isEmpty) {
                      cubit.phoneCountryIdChanged(colombia.id);
                    }
                  }
                } catch (_) {
                  if (mounted) {
                    setState(() => _colombiaId = state.countries.first.id);
                    final cubit = context.read<SocialRegisterCubit>();
                    if (cubit.state.phoneCountryId.isEmpty) {
                      cubit.phoneCountryIdChanged(state.countries.first.id);
                    }
                  }
                }
              }
            },
          ),
        ],
        child: BlocBuilder<LocationsCubit, LocationsState>(
          builder: (context, locState) {
            return BlocBuilder<SocialRegisterCubit, SocialRegisterState>(
              builder: (context, registerState) {
                final cubit = context.read<SocialRegisterCubit>();

                return FixedBottomActionLayout(
                  bottomChild: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      return CustomButton(
                        text: 'Finalizar',
                        isLoading: authState is AuthLoading,
                        onPressed: (!registerState.isValid ||
                                authState is AuthLoading)
                            ? null
                            : () => _onSubmit(cubit),
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
                            initialValue: registerState.name.value,
                            onChanged: cubit.nameChanged,
                            enabled: true,
                            errorText: registerState.isNameAttempted &&
                                    registerState.name.isNotValid
                                ? AppStrings.requiredField
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                              ),
                            ],
                            labelStyle: AppTypography.body6.copyWith(
                              color: const Color(0xFF2E3949).withAlpha(77),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          CustomTextField(
                            label: 'Correo electrónico',
                            initialValue: registerState.email,
                            enabled: false,
                            labelStyle: AppTypography.body6.copyWith(
                              color: const Color(0xFF2E3949).withAlpha(77),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          if (locState is LocationsLoading) ...[
                            const Center(child: CircularProgressIndicator()),
                          ] else if (locState is LocationsLoaded) ...[
                            CountryDropdown(
                              label: 'País de residencia',
                              value: _colombiaId ??
                                  (locState.countries.isNotEmpty
                                      ? locState.countries.first.id
                                      : null),
                              countries: locState.countries,
                              enabled: false,
                              width: double.infinity,
                              onChanged: null,
                            ),
                            const SizedBox(height: AppSpacing.m),

                            IdSelector(
                              initialValue:
                                  registerState.identificationNumber.value,
                              onChanged: cubit.identificationNumberChanged,
                              initialIdType: registerState.identificationType,
                              onIdTypeChanged: cubit.identificationTypeChanged,
                              errorText: registerState.isIdAttempted &&
                                      registerState.identificationNumber
                                          .isNotValid
                                  ? AppStrings.requiredField
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.m),

                            PhoneInputField(
                              label: 'Número de celular (Opcional)',
                              initialValue: registerState.phone.value,
                              onChanged: cubit.phoneChanged,
                              countries: locState.countries,
                              focusNode: _phoneFocusNode,
                              selectedCountryId:
                                  registerState.phoneCountryId.isNotEmpty
                                      ? registerState.phoneCountryId
                                      : (_colombiaId ??
                                          (locState.countries.isNotEmpty
                                              ? locState.countries.first.id
                                              : null)),
                              onCountryChanged: (val) {
                                if (val != null) {
                                  cubit.phoneCountryIdChanged(val);
                                }
                              },
                              maxLength: 15,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              errorText: registerState.isPhoneAttempted &&
                                      registerState.phone.isNotValid &&
                                      registerState.phone.value.isNotEmpty
                                  ? AppStrings.phoneError
                                  : null,
                            ),
                          ],
                          const KeyboardSpacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
