import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
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
import '../../../../core/widgets/layout/fixed_bottom_action_layout.dart';

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

  String? _selectedPhoneCountryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Check if provider exists before calling to avoid testing errors if not mocked,
    // but in app it should be there.
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final user = authState.user;
      _nameController.text = _formatName(user.name);

      if (user.authMethod == 'PHONE') {
        _phoneController.text = user.cellPhone;
        if (user.email.isNotEmpty) _emailController.text = user.email;
        _selectedPhoneCountryId = user.countryId;
      } else {
        _emailController.text = user.email;
        if (user.cellPhone.isNotEmpty) _phoneController.text = user.cellPhone;
        if (user.countryId.isNotEmpty) {
          _selectedPhoneCountryId = user.countryId;
        }
      }
    }
  }

  String _formatName(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final formattedParts = parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });
    return formattedParts.join(' ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppColors.bgOxford,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header imitating ModalPageLayout
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 80,
                                  bottom: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'Mi cuenta',
                                    style: AppTypography.heading2.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 32,
                                right: 24,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),

                          // Scrollable Content
                          Expanded(
                            child: FixedBottomActionLayout(
                              child: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Section 1 Header
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
                                      const SizedBox(height: 24),

                                      // Section 1 Content
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomTextField(
                                              controller: _nameController,
                                              label: 'Nombre completo',
                                            ),
                                            const SizedBox(height: 24),

                                            if (isPhoneLogin) ...[
                                              Text(
                                                'Celular',
                                                style: AppTypography.body5
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              DataValueBox(
                                                value: user.cellPhone.isNotEmpty
                                                    ? user.cellPhone
                                                    : 'No registrado',
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Si necesitas cambiar el celular de tu cuenta, escríbenos a support@animalrecord.com',
                                                style: AppTypography.body4
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                              const SizedBox(height: 24),
                                              CustomTextField(
                                                controller: _emailController,
                                                label: 'Correo electrónico',
                                              ),
                                            ] else ...[
                                              Text(
                                                'Correo electrónico',
                                                style: AppTypography.body5
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              DataValueBox(
                                                value: user.email.isNotEmpty
                                                    ? user.email
                                                    : 'No registrado',
                                              ),
                                              const SizedBox(height: 12),
                                              RichText(
                                                text: TextSpan(
                                                  style: AppTypography.body4
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 13,
                                                      ),
                                                  children: [
                                                    const TextSpan(
                                                      text:
                                                          'Si necesitas cambiar el correo electrónico de tu cuenta, escríbenos a ',
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'support@animalrecord.com',
                                                      style: AppTypography.body4
                                                          .copyWith(
                                                            color: AppColors
                                                                .primaryFrances,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              BlocBuilder<
                                                LocationsCubit,
                                                LocationsState
                                              >(
                                                builder: (context, locationState) {
                                                  return PhoneInputField(
                                                    label:
                                                        'Número celular (Opcional)',
                                                    controller:
                                                        _phoneController,
                                                    countries:
                                                        locationState
                                                            is LocationsLoaded
                                                        ? locationState
                                                              .countries
                                                        : [],
                                                    selectedCountryId:
                                                        _selectedPhoneCountryId,
                                                    onCountryChanged: (id) =>
                                                        setState(
                                                          () =>
                                                              _selectedPhoneCountryId =
                                                                  id,
                                                        ),
                                                    isOptional: true,
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      if (user.authMethod.toLowerCase() ==
                                          'email')
                                        Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              color: const Color(0xFFF4F6F9),
                                              child: Text(
                                                'Contraseña',
                                                style: AppTypography.body3
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 24,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '• • • • • • • •',
                                                        style: AppTypography
                                                            .body3
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textPrimary,
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
                                                          style: AppTypography
                                                              .body3
                                                              .copyWith(
                                                                color: AppColors
                                                                    .primaryFrances,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Última modificación: month, dd, yyyy',
                                                    style: AppTypography.body4
                                                        .copyWith(
                                                          color: AppColors
                                                              .greyMedio,
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
                                      ].contains(user.authMethod.toLowerCase()))
                                        Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              color: const Color(0xFFF4F6F9),
                                              child: Text(
                                                'PIN',
                                                style: AppTypography.body3
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 24,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '• • • •',
                                                        style: AppTypography
                                                            .body3
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textPrimary,
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
                                                          style: AppTypography
                                                              .body3
                                                              .copyWith(
                                                                color: AppColors
                                                                    .primaryFrances,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Última modificación: month, dd, yyyy',
                                                    style: AppTypography.body4
                                                        .copyWith(
                                                          color: AppColors
                                                              .greyMedio,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),

                              bottomChild: CustomButton(
                                text: 'Guardar cambios',
                                isLoading: isUpdating,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final updatedData = <String, dynamic>{
                                      'name': _nameController.text,
                                      if (isPhoneLogin)
                                        'email': _emailController.text,
                                      if (!isPhoneLogin)
                                        'cellPhone': _phoneController.text,
                                      'countryId': user
                                          .countryId, // Keep existing country
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
