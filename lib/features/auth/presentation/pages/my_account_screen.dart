import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/utils/string_formatters.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/phone_input_field.dart';
import '../../../../features/locations/presentation/cubit/locations_cubit.dart';
import '../../../../features/locations/presentation/cubit/locations_state.dart';
import '../../../../core/widgets/buttons/custom_button.dart';
import 'change_password_screen.dart';
import 'change_pin_screen.dart';
import '../../../../core/widgets/display/data_value_box.dart';
import 'package:animal_record/core/utils/error_display.dart';
import '../../../../core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/utils/validation_utils.dart';
import '../../../../core/widgets/utils/keyboard_spacer.dart';
import '../../../../core/constants/country_constants.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:animal_record/core/constants/app_strings.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late FocusNode _phoneFocusNode;

  String? _selectedPhoneCountryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onFieldChanged);
    _emailController = TextEditingController()..addListener(_onFieldChanged);
    _phoneController = TextEditingController()..addListener(_onFieldChanged);
    _phoneFocusNode = FocusNode();

    context.read<LocationsCubit>().fetchCountries();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final user = authState.user;
      _nameController.text = StringFormatters.formatName(user.name);

      // Quick sync strip (works without countries list)
      if (user.authMethod == 'PHONE') {
        _phoneController.text = CountryConstants.stripDialCode(user.cellPhone);
        if (user.email.isNotEmpty) _emailController.text = user.email;
        _selectedPhoneCountryId = user.countryId;
      } else {
        _emailController.text = user.email;
        if (user.cellPhone.isNotEmpty) {
          _phoneController.text = CountryConstants.stripDialCode(
            user.cellPhone,
          );
        }
        if (user.countryId.isNotEmpty) {
          _selectedPhoneCountryId = user.countryId;
        }
      }

      // Async: strip again more precisely once countries are loaded
      _stripDialCodeAsync(user);
    }
  }

  /// After fetching countries we can strip the exact country dialCode,
  /// e.g. both Colombia (+57) and US (+1) are stripped correctly.
  Future<void> _stripDialCodeAsync(UserEntity user) async {
    final cubit = context.read<LocationsCubit>();
    await cubit.fetchCountries();
    if (!mounted) return;

    final locState = cubit.state;
    if (locState is LocationsLoaded && user.countryId.isNotEmpty) {
      try {
        final country = locState.countries.firstWhere(
          (c) => c.id == user.countryId,
        );
        final purePrefix = country.dialCode.replaceAll('+', '');
        if (_phoneController.text.startsWith(purePrefix)) {
          _phoneController.text = _phoneController.text.substring(
            purePrefix.length,
          );
        }
      } catch (_) {}
    }
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _hasChangesAndValid(UserEntity user) {
    final isPhoneLogin = user.authMethod == 'PHONE';

    final currentName = _nameController.text.trim();
    final originalName = StringFormatters.formatName(user.name);
    final nameChanged = currentName != originalName;
    final isNameValid = currentName.isNotEmpty;

    // Phone/country change — applicable to all auth methods
    final currentPhone = _phoneController.text.trim();
    final originalCleanPhone = user.cellPhone.isNotEmpty
        ? CountryConstants.stripDialCode(user.cellPhone)
        : '';
    final phoneChanged = !isPhoneLogin && currentPhone != originalCleanPhone;
    final countryChanged =
        _selectedPhoneCountryId != null &&
        _selectedPhoneCountryId != user.countryId;
    final isPhoneValid =
        isPhoneLogin ||
        currentPhone.isEmpty ||
        currentPhone.replaceAll(RegExp(r'\D'), '').length >= 6;

    // Email change (phone-login users can update email)
    bool emailChanged = false;
    bool isEmailValid = true;
    if (isPhoneLogin) {
      final currentEmail = _emailController.text.trim();
      emailChanged = currentEmail != user.email;
      isEmailValid = currentEmail.isEmpty || _isValidEmail(currentEmail);
    }

    final hasAnyChange =
        nameChanged || phoneChanged || emailChanged || countryChanged;
    final areAllFieldsValid = isNameValid && isPhoneValid && isEmailValid;

    return hasAnyChange && areAllFieldsValid;
  }

  @override
  void didChangeDependencies() {
    // Moved to initState
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && state is! PasswordChangeSuccess) {
          if (state.updateError != null) {
            ErrorDisplay.showError(context, 'Error: ${state.updateError}');
          } else if (state.isUpdating == false && state.updateError == null) {
            ErrorDisplay.showSuccess(context, 'Cambios guardados');
            Navigator.pop(context);
          }
        }
      },
      listenWhen: (previous, current) {
        if (previous is AuthSuccess && current is AuthSuccess) {
          return previous.isUpdating == true && current.isUpdating == false;
        }
        return false;
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Scaffold(body: Center(child: Text('Cargando...')));
          }

          final UserEntity user = state.user;
          final bool isUpdating = state.isUpdating;
          final bool isPhoneLogin = user.authMethod == 'PHONE';

          return KeyboardActions(
            disableScroll: true,
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
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
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
                    },
                  ],
                ),
              ],
            ),
            child: ModalPageLayout(
              title: 'Mi cuenta',
              scrollOnlyWithKeyboard: true,
              trailingIcon: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              bottomChild: CustomButton(
                text: 'Guardar cambios',
                isLoading: isUpdating,
                onPressed: (isUpdating || !_hasChangesAndValid(user))
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          String cellPhone = _phoneController.text.trim();
                          String? finalCountryId =
                              _selectedPhoneCountryId ??
                              (user.countryId.isNotEmpty
                                  ? user.countryId
                                  : null);

                          if (cellPhone.isNotEmpty && finalCountryId != null) {
                            final locState = context
                                .read<LocationsCubit>()
                                .state;
                            if (locState is LocationsLoaded) {
                              try {
                                final country = locState.countries.firstWhere(
                                  (c) => c.id == finalCountryId,
                                );
                                final prefix = country.dialCode;
                                final purePrefix = prefix.replaceAll('+', '');
                                String numbersOnly = cellPhone.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (numbersOnly.startsWith(purePrefix)) {
                                  numbersOnly = numbersOnly.substring(
                                    purePrefix.length,
                                  );
                                }
                                cellPhone = '$prefix$numbersOnly';
                              } catch (_) {}
                            }
                          }

                          final updatedData = <String, dynamic>{
                            'name': _nameController.text,
                            if (isPhoneLogin) 'email': _emailController.text,
                            if (!isPhoneLogin && cellPhone.isNotEmpty)
                              'cellPhone': cellPhone,
                            if (finalCountryId != null)
                              'countryId': finalCountryId,
                          };
                          context.read<AuthBloc>().add(
                            UpdateProfileRequested(
                              userId: user.id,
                              data: updatedData,
                            ),
                          );
                        }
                      },
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: const Color(0xFFF4F6F9),
                      child: Text(
                        'Información de la cuenta',
                        style: AppTypography.body3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Nombre completo',
                          ),
                          const SizedBox(height: AppSpacing.l),

                          if (isPhoneLogin) ...[
                            Text(
                              'Celular',
                              style: AppTypography.body6.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DataValueBox(
                              value: user.cellPhone.isNotEmpty
                                  ? user.cellPhone
                                  : 'No registrado',
                            ),
                            const SizedBox(height: AppSpacing.s),
                            RichText(
                              text: TextSpan(
                                style: AppTypography.body6.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Si necesitas cambiar el celular de tu cuenta, escríbenos a ',
                                  ),
                                  TextSpan(
                                    text: 'support@animalrecord.com',
                                    style: AppTypography.body6.copyWith(
                                      color: AppColors.primaryFrances,
                                      decoration: TextDecoration.underline,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.l),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Correo electrónico (Opcional)',
                              maxLength: 50,
                              validator: ValidationUtils.validateEmail,
                            ),
                          ] else ...[
                            Text(
                              'Correo electrónico',
                              style: AppTypography.body6.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DataValueBox(
                              value: user.email.isNotEmpty
                                  ? user.email
                                  : 'No registrado',
                            ),
                            if ([
                              'google',
                              'microsoft',
                              'apple',
                            ].contains(user.authMethod.toLowerCase())) ...[
                              const SizedBox(height: AppSpacing.m),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_rounded,
                                    color: AppColors.greyMedio,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Correo electrónico de red social',
                                    style: AppTypography.body6,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.m),
                            ] else ...[
                              const SizedBox(height: AppSpacing.s),
                            ],
                            RichText(
                              text: TextSpan(
                                style: AppTypography.body6.copyWith(),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Si necesitas cambiar el correo electrónico de tu cuenta, escríbenos a ',
                                  ),
                                  TextSpan(
                                    text: 'support@animalrecord.com',
                                    style: AppTypography.body6.copyWith(
                                      color: AppColors.primaryFrances,
                                      decoration: TextDecoration.underline,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.l),
                            BlocBuilder<LocationsCubit, LocationsState>(
                              builder: (context, locationState) {
                                return PhoneInputField(
                                  label: 'Número celular (Opcional)',
                                  controller: _phoneController,
                                  focusNode: _phoneFocusNode,
                                  countries: locationState is LocationsLoaded
                                      ? locationState.countries
                                      : [],
                                  selectedCountryId: _selectedPhoneCountryId,
                                  onCountryChanged: (id) => setState(
                                    () => _selectedPhoneCountryId = id,
                                  ),
                                  maxLength: 15,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  isOptional: true,
                                  errorText:
                                      _phoneController.text.trim().isNotEmpty &&
                                          _phoneController.text
                                                  .replaceAll(RegExp(r'\D'), '')
                                                  .length <
                                              10
                                      ? AppStrings.phoneError
                                      : null,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (user.authMethod.toLowerCase() == 'email' ||
                        user.authMethod.toLowerCase() == 'phone')
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            color: const Color(0xFFF4F6F9),
                            child: Text(
                              'Contraseña',
                              style: AppTypography.body3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '• • • • • • • •',
                                      style: AppTypography.body3.copyWith(
                                        color: AppColors.textPrimary,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ChangePasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Cambiar',
                                        style: AppTypography.body3.copyWith(
                                          color: AppColors.primaryFrances,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Última modificación: month, dd, yyyy',
                                  style: AppTypography.body4.copyWith(
                                    color: AppColors.greyMedio,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if ([
                          'google',
                          'microsoft',
                          'apple',
                        ].contains(user.authMethod.toLowerCase()) &&
                        state.isBiometricEnabled)
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            color: const Color(0xFFF4F6F9),
                            child: Text(
                              'PIN',
                              style: AppTypography.body3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '• • • •',
                                      style: AppTypography.body3.copyWith(
                                        color: AppColors.textPrimary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ChangePinScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Cambiar',
                                        style: AppTypography.body3.copyWith(
                                          color: AppColors.primaryFrances,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Última modificación: month, dd, yyyy',
                                  style: AppTypography.body4.copyWith(
                                    color: AppColors.greyMedio,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const KeyboardSpacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
