import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/country_dropdown.dart';
import '../widgets/department_dropdown.dart';
import '../widgets/city_dropdown.dart';
import '../widgets/phone_input_field.dart';
import '../../../../features/locations/presentation/cubit/locations_cubit.dart';
import '../../../../features/locations/presentation/cubit/locations_state.dart';
import '../../../../features/locations/domain/entities/country_entity.dart';
import '../../../../core/widgets/buttons/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _idNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedPhoneCountryId;
  String? _selectedDepartmentId;
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _idNumberController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    // Load countries
    context.read<LocationsCubit>().fetchCountries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize values from user data
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final user = authState.user;
      _nameController.text = _formatName(user.name);
      _idNumberController.text = user.identificationNumber;
      _phoneController.text = user.cellPhone;
      _addressController.text = user.address;

      // Set default location values from user profile
      if (_selectedPhoneCountryId == null) {
        _selectedPhoneCountryId = user.countryId;

        // 1. Fetch departments if we have country
        if (user.countryId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<LocationsCubit>().fetchDepartments(user.countryId);
          });
        }

        // 2. Set Department and fetch cities if we have departmentId
        if (user.departmentId.isNotEmpty) {
          _selectedDepartmentId = user.departmentId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<LocationsCubit>().fetchCities(user.departmentId);
          });
        }

        // 3. Set City if we have cityId
        if (user.cityId.isNotEmpty) {
          _selectedCityId = user.cityId;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatName(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final limitedParts = parts.take(3);

    final formattedParts = limitedParts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return formattedParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          if (state.updateError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al actualizar: ${state.updateError}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.isUpdating == false && state.updateError == null) {
            // Check if we just finished updating (this logic might need refinement if we don't want to show it on initial load.
            // Since isUpdating defaults to false, initial load is false. But we don't wanna show "Success" on every load.
            // However, the event is only emitted after update. But wait, checking just isUpdating == false is risky for initial load.
            // A better way is to check previous state or just assume if we are here and it's a rebuild...
            // Actually, BlocListener only listens to CHANGES.
            // But we need to distinguish "Just Loaded" vs "Update Success".
            // The Bloc emits AuthSuccess with isUpdating=false after update.
            // Let's rely on a separate event or just show it ?
            // For now, let's keep it simple. If we want to be precise, we'd add 'updateSuccess' flag too, but let's try just showing if NO error.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      listenWhen: (previous, current) {
        // Only listen if we are transitioning from isUpdating:true to isUpdating:false
        if (previous is AuthSuccess && current is AuthSuccess) {
          return previous.isUpdating == true && current.isUpdating == false;
        }
        return false;
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // If state is AuthSuccess, we are good. Even if isUpdating is true.
          if (state is! AuthSuccess) {
            return const Scaffold(
              body: Center(child: Text('Usuario no autenticado')),
            );
          }

          final UserEntity user = state.user;
          final bool isUpdating = state.isUpdating;

          return Scaffold(
            backgroundColor: AppColors.bgOxford,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Form Container with everything inside
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
                      child: Column(
                        children: [
                          // Header inside white card with close button
                          Stack(
                            children: [
                              // Centered title with 57px top padding
                              Padding(
                                padding: const EdgeInsets.only(top: 57),
                                child: Center(
                                  child: Text(
                                    'Perfil',
                                    style: AppTypography.heading1.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              // Close button positioned top-right
                              Positioned(
                                top: 24,
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
                          const SizedBox(height: 24),

                          // Avatar Section
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryIndigo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(user.name),
                                    style: AppTypography.heading1.copyWith(
                                      color: Colors.white,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/Edit.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            _formatName(user.name),
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ID
                          Text(
                            '${user.identificationType} ${user.identificationNumber}',
                            style: AppTypography.body4.copyWith(
                              color: AppColors.greyMedio,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _formKey,
                              child: BlocBuilder<LocationsCubit, LocationsState>(
                                builder: (context, locationsState) {
                                  final countries =
                                      locationsState is LocationsLoaded
                                      ? locationsState.countries
                                      : <CountryEntity>[];

                                  // Show email field if user registered with PHONE
                                  final showEmailField =
                                      user.authMethod == 'PHONE';
                                  // Show phone field if user registered with EMAIL or GOOGLE
                                  final showPhoneField =
                                      user.authMethod == 'EMAIL' ||
                                      user.authMethod == 'GOOGLE';

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Email (Conditional - only if registered with phone)
                                      if (showEmailField) ...[
                                        CustomTextField(
                                          controller: _emailController,
                                          label:
                                              'Correo electrónico (Opcional)',
                                          hint: 'ejemplo@correo.com',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Phone (Conditional - only if registered with email/Google)
                                      if (showPhoneField &&
                                          countries.isNotEmpty) ...[
                                        PhoneInputField(
                                          label: 'Número de celular (Opcional)',
                                          controller: _phoneController,
                                          countries: countries,
                                          selectedCountryId:
                                              _selectedPhoneCountryId,
                                          onCountryChanged: (countryId) {
                                            setState(() {
                                              _selectedPhoneCountryId =
                                                  countryId;
                                            });
                                          },
                                          isOptional: true,
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Country (Disabled, Full Width)
                                      if (countries.isNotEmpty)
                                        CountryDropdown(
                                          label: 'País de residencia',
                                          value: user.countryId,
                                          onChanged: null,
                                          countries: countries,
                                          enabled: false,
                                          width: double.infinity,
                                        ),
                                      const SizedBox(height: 16),

                                      // Departamento (Disabled)
                                      if (locationsState is LocationsLoaded)
                                        DepartmentDropdown(
                                          label: 'Departamento',
                                          value: _selectedDepartmentId,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedDepartmentId = value;
                                              _selectedCityId =
                                                  null; // Reset city
                                            });
                                            if (value != null) {
                                              context
                                                  .read<LocationsCubit>()
                                                  .fetchCities(value);
                                            }
                                          },
                                          departments:
                                              locationsState.departments,
                                          enabled: true,
                                        ),
                                      const SizedBox(height: 16),

                                      // Ciudad (Disabled)
                                      if (locationsState is LocationsLoaded)
                                        CityDropdown(
                                          label: 'Ciudad',
                                          value: _selectedCityId,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCityId = value;
                                            });
                                          },
                                          cities: locationsState.cities,
                                          enabled:
                                              _selectedDepartmentId != null,
                                        ),
                                      const SizedBox(height: 16),

                                      // Dirección de residencia (Optional)
                                      CustomTextField(
                                        controller: _addressController,
                                        label:
                                            'Dirección de residencia (Opcional)',
                                        hint: 'Calle 123 # 45-67',
                                      ),
                                      const SizedBox(height: 90),
                                      CustomButton(
                                        text: 'Guardar cambios',
                                        isLoading:
                                            isUpdating, // Use the proper flag
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            final updatedData = <String, dynamic>{
                                              'name': _nameController.text,
                                              'address':
                                                  _addressController.text,
                                              if (showEmailField)
                                                'email': _emailController.text,
                                              if (showPhoneField)
                                                'cellPhone':
                                                    _phoneController.text,
                                              // Include location data if selected
                                              if (_selectedCityId != null)
                                                'cityId': _selectedCityId,
                                              if (_selectedDepartmentId != null)
                                                'departmentId':
                                                    _selectedDepartmentId,
                                              // Keep other fields if necessary or let backend handle partial updates
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
                                      const SizedBox(height: 40),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
