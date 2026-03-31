import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/utils/string_formatters.dart';
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
import 'package:animal_record/core/utils/error_display.dart';
import '../../../../core/widgets/utils/keyboard_spacer.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../cubit/edit_profile_cubit.dart';
import '../cubit/edit_profile_state.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Build only initially to inject provider
        if (previous is! AuthSuccess && current is AuthSuccess) return true;
        return false;
      },
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return const Scaffold(
            body: Center(child: Text('Usuario no autenticado')),
          );
        }
        return BlocProvider(
          create: (_) => EditProfileCubit(user: authState.user),
          child: const EditProfileScreenView(),
        );
      },
    );
  }
}

class EditProfileScreenView extends StatefulWidget {
  const EditProfileScreenView({super.key});

  @override
  State<EditProfileScreenView> createState() => _EditProfileScreenViewState();
}

class _EditProfileScreenViewState extends State<EditProfileScreenView> {
  final FocusNode _phoneFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _loadUserLocations(authState.user);
    } else {
      context.read<LocationsCubit>().fetchCountries();
    }
  }

  Future<void> _loadUserLocations(UserEntity user) async {
    final cubit = context.read<LocationsCubit>();

    await cubit.fetchCountries();
    
    final locState = cubit.state;
    String? colombiaId;

    if (locState is LocationsLoaded) {
      try {
        colombiaId = locState.countries
            .cast<CountryEntity>()
            .firstWhere(
              (c) =>
                  c.dialCode == '+57' ||
                  c.name.toLowerCase().contains('colombia'),
            )
            .id;
      } catch (_) {}
    }

    if (colombiaId != null && mounted) {
      await cubit.fetchDepartments(colombiaId);
    }
    if (user.departmentId.isNotEmpty && mounted) {
      await cubit.fetchCities(user.departmentId);
    }
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );
      if (picked != null && mounted) {
        context.read<AuthBloc>().add(
          UpdateProfilePictureRequested(picked.path),
        );
      }
    } catch (_) {}
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greyBordes,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Cambiar foto de perfil',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (previous is AuthSuccess && current is AuthSuccess) {
              return previous.isUpdating == true && current.isUpdating == false;
            }
            return false;
          },
          listener: (context, state) {
            if (state is AuthSuccess) {
              if (state.updateError != null) {
                ErrorDisplay.showError(
                  context,
                  'Error al actualizar: ${state.updateError}',
                );
              } else {
                ErrorDisplay.showSuccess(
                  context,
                  'Cambios guardados correctamente',
                );
                Navigator.pop(context);
              }
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (previous is AuthSuccess && current is AuthSuccess) {
              return previous.isUploadingPicture == true &&
                  current.isUploadingPicture == false;
            }
            return false;
          },
          listener: (context, state) {
            if (state is AuthSuccess) {
              if (state.profilePictureError != null) {
                ErrorDisplay.showError(
                  context,
                  'Error al subir imagen: ${state.profilePictureError}',
                );
              }
            }
          },
        ),
        BlocListener<LocationsCubit, LocationsState>(
          listenWhen: (previous, current) {
            if (current is LocationsLoaded && current.departments.isEmpty) {
              return true;
            }
            return false;
          },
          listener: (context, state) {
            if (state is LocationsLoaded) {
              final countries = state.countries.cast<CountryEntity>();
              try {
                final colombia = countries.firstWhere(
                  (c) =>
                      c.dialCode == '+57' ||
                      c.name.toLowerCase().contains('colombia'),
                );
                context.read<LocationsCubit>().fetchDepartments(colombia.id);
              } catch (_) {}
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthSuccess) {
            return const Scaffold(
              body: Center(child: Text('Cargando')),
            );
          }

          final UserEntity user = authState.user;
          final bool isUpdating = authState.isUpdating;
          final bool isUploadingPicture = authState.isUploadingPicture;

          return BlocBuilder<EditProfileCubit, EditProfileState>(
            builder: (context, editState) {
              final cubit = context.read<EditProfileCubit>();
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
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                "Aceptar",
                                style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      ],
                    ),
                  ],
                ),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: AppColors.bgOxford,
                  body: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.l),
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
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 100),
                                    child: Column(
                                      children: [
                                        _buildHeader(context),
                                        const SizedBox(height: AppSpacing.l),
                                        _buildAvatar(
                                          user,
                                          isUploadingPicture,
                                          context,
                                        ),
                                        const SizedBox(height: AppSpacing.l),
                                        Text(
                                          StringFormatters.formatName(user.name),
                                          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${user.identificationType} ${user.identificationNumber}',
                                          style: AppTypography.body4.copyWith(color: AppColors.greyMedio),
                                        ),
                                        const SizedBox(height: AppSpacing.xl),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (user.authMethod == 'PHONE') ...[
                                                CustomTextField(
                                                  initialValue: editState.email.value,
                                                  onChanged: cubit.emailChanged,
                                                  label: 'Correo electrónico (Opcional)',
                                                  hint: 'ejemplo@correo.com',
                                                  keyboardType: TextInputType.emailAddress,
                                                  errorText: editState.isEmailAttempted && editState.email.isNotValid 
                                                      ? 'Correo inválido' 
                                                      : null,
                                                ),
                                                const SizedBox(height: AppSpacing.m),
                                              ],
                                              _LocationSelector(
                                                user: user,
                                                phoneFocusNode: _phoneFocusNode,
                                                editState: editState,
                                                cubit: cubit,
                                              ),
                                              CustomTextField(
                                                initialValue: editState.address.value,
                                                onChanged: cubit.addressChanged,
                                                label: 'Dirección de residencia (Opcional)',
                                              ),
                                              const KeyboardSpacer(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 24,
                                  right: 24,
                                  bottom: 24,
                                  child: CustomButton(
                                    text: 'Guardar cambios',
                                    isLoading: isUpdating,
                                    onPressed: (isUpdating || !editState.hasChanges || !editState.isValid)
                                        ? null
                                        : () {
                                            String countryPrefix = '';
                                            final locState = context.read<LocationsCubit>().state;
                                            if (locState is LocationsLoaded) {
                                              final cId = editState.phoneCountryId;
                                              if (cId.isNotEmpty) {
                                                final country = locState.countries.cast<CountryEntity>().firstWhere(
                                                      (c) => c.id == cId,
                                                      orElse: () => locState.countries.first,
                                                    );
                                                countryPrefix = country.dialCode;
                                              }
                                            }

                                            final payload = cubit.buildUpdatePayload(countryPrefix);
                                            context.read<AuthBloc>().add(
                                              UpdateProfileRequested(
                                                userId: user.id,
                                                data: payload,
                                              ),
                                            );
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Text(
              'Perfil',
              style: AppTypography.heading1.copyWith(
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
    );
  }

  Widget _buildAvatar(
    UserEntity user,
    bool isUploadingPicture,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: isUploadingPicture ? null : _showImageSourceSheet,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                user.profilePicture != null && user.profilePicture!.isNotEmpty
                ? Image.network(
                    user.profilePicture!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        _getInitials(user.name),
                        style: AppTypography.heading1.copyWith(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(user.name),
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                  ),
          ),
          if (isUploadingPicture)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          if (!isUploadingPicture)
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
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final UserEntity user;
  final FocusNode? phoneFocusNode;
  final EditProfileState editState;
  final EditProfileCubit cubit;

  const _LocationSelector({
    required this.user,
    this.phoneFocusNode,
    required this.editState,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final showPhoneField = user.authMethod != 'PHONE';

    return BlocBuilder<LocationsCubit, LocationsState>(
      builder: (context, locationsState) {
        final countries = locationsState is LocationsLoaded
            ? locationsState.countries
            : <CountryEntity>[];

        final colombiaId = countries.isNotEmpty
            ? (countries.cast<CountryEntity>().any((c) =>
                    c.dialCode == '+57' ||
                    c.name.toLowerCase().contains('colombia'))
                ? countries
                    .cast<CountryEntity>()
                    .firstWhere((c) =>
                        c.dialCode == '+57' ||
                        c.name.toLowerCase().contains('colombia'))
                    .id
                : countries.first.id)
            : '';

        return Column(
          children: [
            if (showPhoneField && countries.isNotEmpty) ...[
              PhoneInputField(
                label: 'Número de celular (Opcional)',
                initialValue: editState.phone.value,
                onChanged: cubit.phoneChanged,
                focusNode: phoneFocusNode,
                countries: countries,
                selectedCountryId: editState.phoneCountryId.isEmpty ? colombiaId : editState.phoneCountryId,
                onCountryChanged: (val) {
                  if (val != null) {
                    final country = countries.cast<CountryEntity>().firstWhere(
                          (c) => c.id == val,
                          orElse: () => countries.first,
                        );
                    cubit.phoneCountryIdChanged(val, country.dialCode);
                  }
                },
                errorText: editState.isPhoneAttempted && editState.phone.isNotValid && editState.phone.value.isNotEmpty
                    ? 'Teléfono inválido' 
                    : null,
                isOptional: true,
              ),
              const SizedBox(height: AppSpacing.m),
            ],

            if (countries.isNotEmpty)
              CountryDropdown(
                label: 'País de residencia',
                value: colombiaId,
                onChanged: null,
                countries: countries,
                enabled: false,
                width: double.infinity,
              ),
            const SizedBox(height: AppSpacing.m),

            if (locationsState is LocationsLoaded)
              DepartmentDropdown(
                label: 'Departamento',
                value: editState.departmentId.isNotEmpty ? editState.departmentId : null,
                onChanged: (value) {
                  if (value != null) {
                    cubit.departmentChanged(value);
                    context.read<LocationsCubit>().fetchCities(value);
                  }
                },
                departments: locationsState.departments,
              )
            else
              const DepartmentDropdown(
                label: 'Departamento',
                value: null,
                onChanged: null,
                departments: [],
              ),
            const SizedBox(height: AppSpacing.m),

            if (locationsState is LocationsLoaded)
              CityDropdown(
                label: 'Ciudad / Municipio',
                value: editState.cityId.isNotEmpty ? editState.cityId : null,
                onChanged: (value) {
                  if (value != null) {
                    cubit.cityChanged(value);
                  }
                },
                cities: locationsState.cities,
              )
            else
              const CityDropdown(
                label: 'Ciudad / Municipio',
                value: null,
                onChanged: null,
                cities: [],
              ),
            const SizedBox(height: AppSpacing.m),
          ],
        );
      },
    );
  }
}
