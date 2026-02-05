import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_input_field.dart';
import '../../../../features/locations/presentation/cubit/locations_cubit.dart';
import '../../../../features/locations/presentation/cubit/locations_state.dart';
import '../../../../core/widgets/buttons/custom_button.dart';
import '../bloc/auth_event.dart';
import 'change_password_screen.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.updateError}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.isUpdating == false && state.updateError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cambios guardados'),
                backgroundColor: Colors.green,
              ),
            );
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
          if (state is! AuthSuccess)
            return const Scaffold(body: Center(child: Text('Cargando...')));

          final UserEntity user = state.user;
          final bool isUpdating = state.isUpdating;
          final bool isPhoneLogin = user.authMethod == 'PHONE';

          return Scaffold(
            backgroundColor: AppColors.bgOxford,
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // The White Card
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 100,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Area
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
                                            style: AppTypography.heading2
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 32,
                                        right: 32,
                                        child: IconButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          icon: const Icon(Icons.close),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Section 1 Header
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    color: const Color(
                                      0xFFF4F6F9,
                                    ), // Light grey section bg
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
                                          // Phone Login Logic
                                          Text(
                                            'Celular',
                                            style: AppTypography.body5.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDatavalueBox(
                                            user.cellPhone.isNotEmpty
                                                ? user.cellPhone
                                                : 'No registrado',
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Si necesitas cambiar el celular de tu cuenta, escríbenos a support@animalrecord.com',
                                            style: AppTypography.body4.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          CustomTextField(
                                            controller: _emailController,
                                            label: 'Correo electrónico',
                                          ),
                                        ] else ...[
                                          // Email Login Logic
                                          Text(
                                            'Correo electrónico',
                                            style: AppTypography.body5.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildDatavalueBox(
                                            user.email.isNotEmpty
                                                ? user.email
                                                : 'No registrado',
                                          ),
                                          const SizedBox(height: 12),
                                          RichText(
                                            text: TextSpan(
                                              style: AppTypography.body4
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
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
                                                controller: _phoneController,
                                                countries:
                                                    locationState
                                                        is LocationsLoaded
                                                    ? locationState.countries
                                                    : [],
                                                selectedCountryId:
                                                    _selectedPhoneCountryId,
                                                onCountryChanged: (id) => setState(
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

                                  if (![
                                    'google',
                                    'microsoft',
                                    'apple',
                                  ].contains(user.authMethod.toLowerCase()))
                                    Column(
                                      children: [
                                        // Section 2 Header: Password
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
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '• • • • • • • •',
                                                    style: AppTypography.body3
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
                                                      style: AppTypography.body3
                                                          .copyWith(
                                                            color: AppColors
                                                                .primaryFrances,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Última modificación: month, dd, yyyy', // Placeholder
                                                style: AppTypography.body4
                                                    .copyWith(
                                                      color:
                                                          AppColors.greyMedio,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  const Spacer(),

                                  // Submit Button
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: CustomButton(
                                      text: 'Guardar cambios',
                                      isLoading: isUpdating,
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          final updatedData = <String, dynamic>{
                                            'name': _nameController.text,
                                            if (isPhoneLogin)
                                              'email': _emailController.text,
                                            if (!isPhoneLogin)
                                              'cellPhone':
                                                  _phoneController.text,
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
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDatavalueBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyClaro),
      ),
      child: Text(
        value,
        style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
