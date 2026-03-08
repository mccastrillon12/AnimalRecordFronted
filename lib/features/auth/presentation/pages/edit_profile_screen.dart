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

  final ImagePicker _imagePicker = ImagePicker();

  void _onFieldChanged() {
    setState(() {});
  }

  bool _hasChangesAndValid(UserEntity user) {
    if (_addressController.text.trim() != user.address) return true;

    if (_phoneController.text.trim() != user.cellPhone) return true;

    final currentCountryId = _selectedPhoneCountryId ?? '';
    if (currentCountryId != user.countryId &&
        !(currentCountryId.isEmpty && user.countryId.isEmpty))
      return true;

    final currentDeptId = _selectedDepartmentId ?? '';
    if (currentDeptId != user.departmentId &&
        !(currentDeptId.isEmpty && user.departmentId.isEmpty))
      return true;

    final currentCityId = _selectedCityId ?? '';
    if (currentCityId != user.cityId &&
        !(currentCityId.isEmpty && user.cityId.isEmpty))
      return true;

    if (user.authMethod == 'PHONE') {
      if (_emailController.text.trim() != user.email) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onFieldChanged);
    _emailController = TextEditingController()..addListener(_onFieldChanged);
    _idNumberController = TextEditingController()..addListener(_onFieldChanged);
    _phoneController = TextEditingController()..addListener(_onFieldChanged);
    _addressController = TextEditingController()..addListener(_onFieldChanged);

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final user = authState.user;
      _nameController.text = StringFormatters.formatName(user.name);
      _idNumberController.text = user.identificationNumber;
      _phoneController.text = user.cellPhone;
      _addressController.text = user.address;

      _loadUserLocations(user);
    } else {
      context.read<LocationsCubit>().fetchCountries();
    }
  }

  Future<void> _loadUserLocations(UserEntity user) async {
    _selectedPhoneCountryId = user.countryId.isNotEmpty ? user.countryId : null;
    _selectedDepartmentId = user.departmentId.isNotEmpty
        ? user.departmentId
        : null;
    _selectedCityId = user.cityId.isNotEmpty ? user.cityId : null;

    final cubit = context.read<LocationsCubit>();

    await cubit.fetchCountries();

    if (user.countryId.isNotEmpty && mounted) {
      await cubit.fetchDepartments(user.countryId);
    }

    if (user.departmentId.isNotEmpty && mounted) {
      await cubit.fetchCities(user.departmentId);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _idNumberController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality:
            95, // calidad original — la compresión real la hace flutter_image_compress en el bloc
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
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Scaffold(
              body: Center(child: Text('Usuario no autenticado')),
            );
          }

          final UserEntity user = state.user;
          final bool isUpdating = state.isUpdating;
          final bool isUploadingPicture = state.isUploadingPicture;

          return Scaffold(
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
                                    style: AppTypography.heading2.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${user.identificationType} ${user.identificationNumber}',
                                    style: AppTypography.body4.copyWith(
                                      color: AppColors.greyMedio,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (user.authMethod == 'PHONE') ...[
                                            CustomTextField(
                                              controller: _emailController,
                                              label:
                                                  'Correo electrónico (Opcional)',
                                              hint: 'ejemplo@correo.com',
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.m,
                                            ),
                                          ],
                                          _LocationSelector(
                                            user: user,
                                            phoneController: _phoneController,
                                            selectedPhoneCountryId:
                                                _selectedPhoneCountryId,
                                            selectedDepartmentId:
                                                _selectedDepartmentId,
                                            selectedCityId: _selectedCityId,
                                            onPhoneCountryChanged: (val) =>
                                                setState(
                                                  () =>
                                                      _selectedPhoneCountryId =
                                                          val,
                                                ),
                                            onDepartmentChanged: (val) {
                                              setState(() {
                                                _selectedDepartmentId = val;
                                                _selectedCityId = null;
                                              });
                                            },
                                            onCityChanged: (val) => setState(
                                              () => _selectedCityId = val,
                                            ),
                                          ),
                                          CustomTextField(
                                            controller: _addressController,
                                            label:
                                                'Dirección de residencia (Opcional)',
                                          ),
                                          const KeyboardSpacer(),
                                        ],
                                      ),
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
                              onPressed:
                                  (isUpdating || !_hasChangesAndValid(user))
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        String cellPhone = _phoneController.text
                                            .trim();
                                        if (cellPhone.isNotEmpty &&
                                            !cellPhone.startsWith('+')) {
                                          final state = context
                                              .read<LocationsCubit>()
                                              .state;
                                          if (state is LocationsLoaded) {
                                            final countryId =
                                                _selectedPhoneCountryId ??
                                                user.countryId;
                                            if (countryId.isNotEmpty) {
                                              final country = state.countries
                                                  .cast<CountryEntity>()
                                                  .firstWhere(
                                                    (c) => c.id == countryId,
                                                    orElse: () =>
                                                        state.countries.first,
                                                  );
                                              cellPhone =
                                                  '${country.dialCode}$cellPhone'
                                                      .replaceAll(' ', '');
                                            }
                                          }
                                        }

                                        final updatedData = <String, dynamic>{
                                          'name': _nameController.text,
                                          'address': _addressController.text,
                                          if (user.authMethod == 'PHONE')
                                            'email': _emailController.text,
                                          if (user.authMethod == 'EMAIL' ||
                                              user.authMethod == 'GOOGLE')
                                            'cellPhone': cellPhone,
                                          if (_selectedCityId != null)
                                            'cityId': _selectedCityId,
                                          if (_selectedDepartmentId != null)
                                            'departmentId':
                                                _selectedDepartmentId,
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
          // Avatar principal: foto real o iniciales
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

          // Loading overlay cuando se está subiendo
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

          // Botón de edición (lápiz) en la esquina
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
  final TextEditingController phoneController;
  final String? selectedPhoneCountryId;
  final String? selectedDepartmentId;
  final String? selectedCityId;
  final ValueChanged<String?> onPhoneCountryChanged;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onCityChanged;

  const _LocationSelector({
    required this.user,
    required this.phoneController,
    required this.selectedPhoneCountryId,
    required this.selectedDepartmentId,
    required this.selectedCityId,
    required this.onPhoneCountryChanged,
    required this.onDepartmentChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showPhoneField =
        user.authMethod == 'EMAIL' || user.authMethod == 'GOOGLE';

    return BlocBuilder<LocationsCubit, LocationsState>(
      builder: (context, locationsState) {
        final countries = locationsState is LocationsLoaded
            ? locationsState.countries
            : <CountryEntity>[];

        return Column(
          children: [
            if (showPhoneField && countries.isNotEmpty) ...[
              PhoneInputField(
                label: 'Número de celular (Opcional)',
                controller: phoneController,
                countries: countries,
                selectedCountryId: selectedPhoneCountryId,
                onCountryChanged: onPhoneCountryChanged,
                isOptional: true,
              ),
              const SizedBox(height: AppSpacing.m),
            ],

            if (countries.isNotEmpty)
              CountryDropdown(
                label: 'País de residencia',
                value: user.countryId,
                onChanged: null,
                countries: countries,
                enabled: false,
                width: double.infinity,
              ),
            const SizedBox(height: AppSpacing.m),

            if (locationsState is LocationsLoaded)
              DepartmentDropdown(
                label: 'Departamento',
                value: selectedDepartmentId,
                onChanged: (value) {
                  onDepartmentChanged(value);
                  if (value != null) {
                    context.read<LocationsCubit>().fetchCities(value);
                  }
                },
                departments: locationsState.departments,
                enabled: true,
              ),
            const SizedBox(height: AppSpacing.m),

            if (locationsState is LocationsLoaded)
              CityDropdown(
                label: 'Ciudad',
                value: selectedCityId,
                onChanged: onCityChanged,
                cities: locationsState.cities,
                enabled: selectedDepartmentId != null,
              ),
            const SizedBox(height: AppSpacing.m),
          ],
        );
      },
    );
  }
}
