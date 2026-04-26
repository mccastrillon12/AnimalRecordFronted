import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/domain/entities/update_animal_params.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_info_basic_tab.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_info_additional_tab.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_info_general_tab.dart';
import 'package:animal_record/core/widgets/layout/fixed_bottom_action_layout.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_cubit.dart';

class AnimalInfoScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalInfoScreen({super.key, required this.animal});

  @override
  State<AnimalInfoScreen> createState() => _AnimalInfoScreenState();
}

class _AnimalInfoScreenState extends State<AnimalInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // — Live animal model that updates from cubit state —
  late AnimalModel _currentAnimal;

  // — Datos básicos state —
  late TextEditingController _nameController;
  String? _reproductiveState;
  DateTime? _birthDate;
  bool _unknownExactDate = false;
  late TextEditingController _weightKgController;
  late TextEditingController _colorDescController;
  String? _hasIdentification;
  String? _belongsToAssociation;
  String? _selectedAssociation;
  String? _selectedIdentificationType;
  final _identificationNumberController = TextEditingController();

  // — Info Adicional state —
  List<String> _selectedTemperaments = [];
  late TextEditingController _allergyController;
  final Map<String, bool> _diagnoses = {
    'Ninguno/Desconocido': false,
    'Mielopatía degenerativa': false,
    'Displasia de cadera': false,
    'Leishmaniasis': false,
    'Otro': false,
  };
  late TextEditingController _otherDiagnosisController;
  String? _housingType;
  String? _purpose;
  late TextEditingController _feedingTypeController;
  late TextEditingController _birthTypeController;
  late TextEditingController _birthConditionController;

  // — Photo state (for instant visual feedback) —
  String? _localPhotoPath;
  bool _photoDeleted = false;

  // — Original values for change detection —
  late String _originalName;
  late String? _originalReproductiveState;
  late DateTime? _originalBirthDate;
  late String? _originalColorDesc;
  late String? _originalHasIdentification;
  late String? _originalBelongsToAssociation;
  late String? _originalSelectedAssociation;
  late String? _originalSelectedIdentificationType;
  late List<String> _originalTemperaments;
  late String? _originalAllergy;
  late Map<String, bool> _originalDiagnoses;
  late String? _originalHousingType;
  late String? _originalPurpose;
  late String? _originalFeedingType;
  late String? _originalBirthType;
  late String? _originalBirthCondition;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _initializeFromAnimal();
    
    // Fetch detailed info (createdAt, updatedAt, ownerName) which are not returned by the owner list endpoint
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<AnimalCubit>().loadAnimalDetails(widget.animal.id);
        
        // Ensure species are loaded to resolve speciesId
        final catalogsCubit = context.read<CatalogsCubit>();
        if (catalogsCubit.species.isEmpty) {
          await catalogsCubit.loadSpecies();
        }
        
        if (mounted) {
          final speciesId = _getSpeciesId(context, widget.animal.species);
          catalogsCubit.loadAnimalCatalogs(speciesId: speciesId);
        }
      }
    });
  }

  void _initializeFromAnimal() {
    final a = widget.animal;

    _nameController = TextEditingController(text: a.name)
      ..addListener(_onFieldChanged);
    _reproductiveState = _mapReproductiveStatus(a.reproductiveStatus);
    _birthDate = a.birthdate != null && a.birthdate!.isNotEmpty
        ? DateTime.tryParse(a.birthdate!)
        : null;
    _weightKgController = TextEditingController(
      text: a.weight != null ? a.weight.toString() : '',
    )..addListener(_onFieldChanged);
    _colorDescController = TextEditingController(text: a.colorAndMarkings ?? '')
      ..addListener(_onFieldChanged);
    _hasIdentification = a.hasChip ? 'si' : 'no';
    _selectedIdentificationType = a.identificationType;
    _belongsToAssociation = a.isAssociationMember ? 'si' : 'no';
    _selectedAssociation = a.registrationAssociation;

    _selectedTemperaments = List<String>.from(a.temperament);
    _allergyController = TextEditingController(text: a.allergies ?? '')
      ..addListener(_onFieldChanged);

    // Set diagnoses from animal data
    for (final d in a.diagnosis) {
      if (_diagnoses.containsKey(d)) {
        _diagnoses[d] = true;
      } else if (d != 'Ninguno') {
        _diagnoses['Otro'] = true;
        _otherDiagnosisController = TextEditingController(text: d);
      }
    }
    if (!a.diagnosis.any((d) => !_diagnoses.containsKey(d) && d != 'Ninguno')) {
      _otherDiagnosisController = TextEditingController();
    }
    _otherDiagnosisController.addListener(_onFieldChanged);

    _housingType = a.housingType;
    _purpose = a.purpose;
    _feedingTypeController = TextEditingController(text: a.feedingType ?? '')
      ..addListener(_onFieldChanged);
    _birthTypeController = TextEditingController(text: a.birthType ?? '')
      ..addListener(_onFieldChanged);
    _birthConditionController = TextEditingController(
      text: a.birthCondition ?? '',
    )..addListener(_onFieldChanged);

    // Save originals
    _originalName = a.name;
    _originalReproductiveState = _reproductiveState;
    _originalBirthDate = _birthDate;
    _originalColorDesc = a.colorAndMarkings ?? '';
    _originalHasIdentification = _hasIdentification;
    _originalSelectedIdentificationType = _selectedIdentificationType;
    _originalBelongsToAssociation = _belongsToAssociation;
    _originalSelectedAssociation = _selectedAssociation;
    _originalTemperaments = List<String>.from(a.temperament);
    _originalAllergy = a.allergies ?? '';
    _originalDiagnoses = Map<String, bool>.from(_diagnoses);
    _originalHousingType = a.housingType;
    _originalPurpose = a.purpose;
    _originalFeedingType = a.feedingType ?? '';
    _originalBirthType = a.birthType ?? '';
    _originalBirthCondition = a.birthCondition ?? '';
  }

  String? _mapReproductiveStatus(String status) {
    switch (status.toUpperCase()) {
      case 'INTACT':
      case 'NO_ESTERILIZADO':
        return 'no_esterilizado';
      case 'NEUTERED':
      case 'SPAYED':
      case 'ESTERILIZADO':
        return 'esterilizado';
      case 'UNKNOWN':
      case 'DESCONOCIDO':
        return 'desconocido';
      default:
        if (status.isNotEmpty) return status.toLowerCase();
        return null;
    }
  }

  String? _getSpeciesId(BuildContext context, String apiSpeciesName) {
    final speciesList = context.read<CatalogsCubit>().species;
    for (final s in speciesList) {
      if (_mapSpeciesToApi(s.name) == apiSpeciesName) {
        return s.id;
      }
    }
    return null;
  }

  String _mapSpeciesToApi(String name) {
    switch (name.toLowerCase()) {
      case 'canino':
        return 'DOG';
      case 'felino':
        return 'CAT';
      case 'bovino':
        return 'BOVINE';
      case 'equino':
        return 'EQUINE';
      default:
        return name.toUpperCase();
    }
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    if (_nameController.text.trim() != _originalName) return true;
    if (_reproductiveState != _originalReproductiveState) return true;
    if (_birthDate != _originalBirthDate) return true;
    if (_colorDescController.text.trim() != _originalColorDesc) return true;
    if (_hasIdentification != _originalHasIdentification) return true;
    if (_selectedIdentificationType != _originalSelectedIdentificationType) return true;
    if (_belongsToAssociation != _originalBelongsToAssociation) return true;
    if (_selectedAssociation != _originalSelectedAssociation) return true;
    if (_selectedTemperaments.length != _originalTemperaments.length) {
      return true;
    }
    for (int i = 0; i < _selectedTemperaments.length; i++) {
      if (_selectedTemperaments[i] != _originalTemperaments[i]) return true;
    }
    if (_allergyController.text.trim() != _originalAllergy) return true;
    for (final key in _diagnoses.keys) {
      if (_diagnoses[key] != _originalDiagnoses[key]) return true;
    }
    if (_housingType != _originalHousingType) return true;
    if (_purpose != _originalPurpose) return true;
    if (_feedingTypeController.text.trim() != _originalFeedingType) return true;
    if (_birthTypeController.text.trim() != _originalBirthType) return true;
    if (_birthConditionController.text.trim() != _originalBirthCondition) {
      return true;
    }
    return false;
  }

  void _saveNameOnly(String newName) {
    final selectedDiagnoses = _diagnoses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final params = UpdateAnimalParams(
      id: _currentAnimal.id,
      name: newName,
      species: _currentAnimal.species,
      breed: _currentAnimal.breed ?? '',
      sex: _currentAnimal.sex == 'macho' ? 'MALE' : 'FEMALE',
      reproductiveStatus: _reproductiveState ?? '',
      birthdate: _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      hasChip: _hasIdentification == 'si',
      isAssociationMember: _belongsToAssociation == 'si',
      temperament: _selectedTemperaments.isEmpty
          ? ['Desconocido']
          : _selectedTemperaments,
      diagnosis: selectedDiagnoses.isEmpty ? ['Ninguno'] : selectedDiagnoses,
      ownerId: _currentAnimal.ownerId,
      weight: double.tryParse(_weightKgController.text.trim()),
      colorAndMarkings: _colorDescController.text.trim().isNotEmpty
          ? _colorDescController.text.trim()
          : null,
      allergies: _allergyController.text.trim().isNotEmpty
          ? _allergyController.text.trim()
          : null,
      housingType: _housingType,
      purpose: _purpose,
      feedingType: _feedingTypeController.text.trim().isNotEmpty
          ? _feedingTypeController.text.trim()
          : null,
      birthType: _birthTypeController.text.trim().isNotEmpty
          ? _birthTypeController.text.trim()
          : null,
      birthCondition: _birthConditionController.text.trim().isNotEmpty
          ? _birthConditionController.text.trim()
          : null,
      identificationType: _hasIdentification == 'si' ? _selectedIdentificationType : null,
      registrationAssociation: _belongsToAssociation == 'si' ? _selectedAssociation : null,
    );

    context.read<AnimalCubit>().updateAnimal(params);
  }

  void _saveChanges() {
    final selectedDiagnoses = _diagnoses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final params = UpdateAnimalParams(
      id: _currentAnimal.id,
      name: _nameController.text.trim(),
      species: _currentAnimal.species,
      breed: _currentAnimal.breed ?? '',
      sex: _currentAnimal.sex == 'macho' ? 'MALE' : 'FEMALE',
      reproductiveStatus: _reproductiveState ?? '',
      birthdate: _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      hasChip: _hasIdentification == 'si',
      isAssociationMember: _belongsToAssociation == 'si',
      temperament: _selectedTemperaments.isEmpty
          ? ['Desconocido']
          : _selectedTemperaments,
      diagnosis: selectedDiagnoses.isEmpty ? ['Ninguno'] : selectedDiagnoses,
      ownerId: _currentAnimal.ownerId,
      weight: double.tryParse(_weightKgController.text.trim()),
      colorAndMarkings: _colorDescController.text.trim().isNotEmpty
          ? _colorDescController.text.trim()
          : null,
      allergies: _allergyController.text.trim().isNotEmpty
          ? _allergyController.text.trim()
          : null,
      housingType: _housingType,
      purpose: _purpose,
      feedingType: _feedingTypeController.text.trim().isNotEmpty
          ? _feedingTypeController.text.trim()
          : null,
      birthType: _birthTypeController.text.trim().isNotEmpty
          ? _birthTypeController.text.trim()
          : null,
      birthCondition: _birthConditionController.text.trim().isNotEmpty
          ? _birthConditionController.text.trim()
          : null,
      identificationType: _hasIdentification == 'si' ? _selectedIdentificationType : null,
      registrationAssociation: _belongsToAssociation == 'si' ? _selectedAssociation : null,
    );

    context.read<AnimalCubit>().updateAnimal(params);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _weightKgController.dispose();
    _colorDescController.dispose();
    _identificationNumberController.dispose();
    _allergyController.dispose();
    _otherDiagnosisController.dispose();
    _feedingTypeController.dispose();
    _birthTypeController.dispose();
    _birthConditionController.dispose();
    super.dispose();
  }

  void _updateOriginalsToCurrent() {
    setState(() {
      _originalName = _nameController.text.trim();
      _originalReproductiveState = _reproductiveState;
      _originalBirthDate = _birthDate;
      _originalColorDesc = _colorDescController.text.trim();
      _originalHasIdentification = _hasIdentification;
      _originalBelongsToAssociation = _belongsToAssociation;
      _originalSelectedAssociation = _selectedAssociation;
      _originalTemperaments = List<String>.from(_selectedTemperaments);
      _originalAllergy = _allergyController.text.trim();
      _originalDiagnoses = Map<String, bool>.from(_diagnoses);
      _originalHousingType = _housingType;
      _originalPurpose = _purpose;
      _originalFeedingType = _feedingTypeController.text.trim();
      _originalBirthType = _birthTypeController.text.trim();
      _originalBirthCondition = _birthConditionController.text.trim();
    });
  }

  void _showImageSourceSheet() {
    final picker = ImagePicker();
    final hasExistingPicture = _currentAnimal.imageUrl != null || _localPhotoPath != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
                  'Foto del animal',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tomar foto'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 95,
                    );
                    if (picked != null && mounted) {
                      // Instant visual feedback
                      setState(() {
                        _localPhotoPath = picked.path;
                        _photoDeleted = false;
                      });
                      ErrorDisplay.showSuccess(context, 'Foto actualizada exitosamente.');
                      // Then upload in background
                      context.read<AnimalCubit>().updateProfilePicture(
                        _currentAnimal.id,
                        picked.path,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Elegir de la galería'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1920,
                      maxHeight: 1920,
                      imageQuality: 95,
                    );
                    if (picked != null && mounted) {
                      // Instant visual feedback
                      setState(() {
                        _localPhotoPath = picked.path;
                        _photoDeleted = false;
                      });
                      ErrorDisplay.showSuccess(context, 'Foto actualizada exitosamente.');
                      // Then upload in background
                      context.read<AnimalCubit>().updateProfilePicture(
                        _currentAnimal.id,
                        picked.path,
                      );
                    }
                  },
                ),
                if (hasExistingPicture)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.errorRojo,
                    ),
                    title: Text(
                      'Eliminar foto',
                      style: TextStyle(color: AppColors.errorRojo),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      // Instant visual feedback
                      setState(() {
                        _localPhotoPath = null;
                        _photoDeleted = true;
                      });
                      ErrorDisplay.showSuccess(context, 'Foto eliminada exitosamente.');
                      // Then delete in background
                      context.read<AnimalCubit>().deleteProfilePicture(
                        _currentAnimal.id,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnimalCubit, AnimalState>(
      listenWhen: (previous, current) {
        return current is AnimalUpdated ||
            current is AnimalPictureUploaded ||
            current is AnimalError;
      },
      listener: (context, state) {
        if (state is AnimalUpdated) {
          // Refresh _currentAnimal with fresh data from the backend
          try {
            final updatedEntity = state.allAnimals.firstWhere(
              (a) => a.id == _currentAnimal.id,
            );
            setState(() {
              _currentAnimal = AnimalModel.fromEntity(updatedEntity);
            });
          } catch (_) {}
          ErrorDisplay.showSuccess(
            context,
            'Información guardada exitosamente.',
          );
          _updateOriginalsToCurrent();
          context.read<AnimalCubit>().resetToLoaded();
        } else if (state is AnimalPictureUploaded) {
          // Refresh _currentAnimal with updated picture URL
          try {
            final updatedEntity = state.allAnimals.firstWhere(
              (a) => a.id == _currentAnimal.id,
            );
            setState(() {
              _currentAnimal = AnimalModel.fromEntity(updatedEntity);
            });
          } catch (_) {}
          context.read<AnimalCubit>().resetToLoaded();
        } else if (state is AnimalError) {
          ErrorDisplay.showError(context, state.message);
          context.read<AnimalCubit>().resetToLoaded();
        }
      },
      buildWhen: (previous, current) {
        // Rebuild when animals are loaded (initial fetch or re-fetch)
        return current is AnimalsLoaded;
      },
      builder: (context, state) {
        // Update _currentAnimal from the latest loaded state
        if (state is AnimalsLoaded) {
          try {
            final freshEntity = state.animals.firstWhere(
              (a) => a.id == _currentAnimal.id,
            );
            // Use a post-frame callback to avoid setState during build
            final freshModel = AnimalModel.fromEntity(freshEntity);
            if (freshModel.createdAt != _currentAnimal.createdAt ||
                freshModel.updatedAt != _currentAnimal.updatedAt ||
                freshModel.ownerName != _currentAnimal.ownerName ||
                freshModel.name != _currentAnimal.name ||
                freshModel.imageUrl != _currentAnimal.imageUrl) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentAnimal = freshModel;
                  });
                }
              });
            }
          } catch (_) {}
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundDegrade,
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: const SizedBox(height: AppSpacing.l),
                ),
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
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.m,
                              right: AppSpacing.l,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Tab bar with bottom shadow (clipped at the top)
                        ClipRect(
                          clipper: _BottomShadowClipper(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0F1925,
                                  ).withValues(alpha: 0.08),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabController,
                              dividerColor:
                                  Colors.transparent, // Disable default line
                              labelColor: AppColors.textPrimary,
                              unselectedLabelColor: AppColors.greyMedio,
                              labelStyle: AppTypography.body3.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: AppTypography.body4,
                              indicatorColor: AppColors.primaryFrances,
                              indicatorWeight: 2,
                              indicatorSize: TabBarIndicatorSize
                                  .label, // Indicator matches text width
                              tabs: const [
                                Tab(text: 'Datos básicos'),
                                Tab(text: 'Info. Adicional'),
                                Tab(text: 'General'),
                              ],
                            ),
                          ),
                        ),

                        // Tab content
                        Expanded(
                          child: FixedBottomActionLayout(
                            bottomChild: _tabController.index == 2
                                ? OutlinedButton(
                                    onPressed: () {
                                      // TODO: Implement inactivate
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.errorRojo,
                                      minimumSize: const Size(
                                        double.infinity,
                                        36,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: const BorderSide(
                                        color: AppColors.errorRojo,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppBorders.medium(),
                                      ),
                                    ),
                                    child: Text(
                                      'Inactivar historia',
                                      style: AppTypography.body3.copyWith(
                                        color: AppColors.errorRojo,
                                      ),
                                    ),
                                  )
                                : (_hasChanges
                                      ? BlocBuilder<AnimalCubit, AnimalState>(
                                          builder: (context, state) {
                                            final isUpdating =
                                                state is AnimalUpdating;
                                            return CustomButton(
                                              text: 'Guardar cambios',
                                              isLoading: isUpdating,
                                              onPressed: isUpdating
                                                  ? null
                                                  : _saveChanges,
                                            );
                                          },
                                        )
                                      : const SizedBox.shrink()),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                AnimalInfoBasicTab(
                                  animal: _currentAnimal,
                                  nameController: _nameController,
                                  reproductiveState: _reproductiveState,
                                  onReproductiveStateChanged: (v) =>
                                      setState(() => _reproductiveState = v),
                                  birthDate: _birthDate,
                                  onBirthDateChanged: (v) =>
                                      setState(() => _birthDate = v),
                                  unknownExactDate: _unknownExactDate,
                                  onUnknownExactDateChanged: (v) =>
                                      setState(() => _unknownExactDate = v),
                                  weightKgController: _weightKgController,
                                  colorDescController: _colorDescController,
                                  hasIdentification: _hasIdentification,
                                  onHasIdentificationChanged: (v) => setState(() {
                                    _hasIdentification = v;
                                    if (v != 'si') {
                                      _selectedIdentificationType = null;
                                    }
                                  }),
                                  selectedIdentificationType: _selectedIdentificationType,
                                  onIdentificationTypeChanged: (v) =>
                                      setState(() => _selectedIdentificationType = v),
                                  identificationNumberController: _identificationNumberController,
                                  belongsToAssociation: _belongsToAssociation,
                                  onBelongsToAssociationChanged: (v) => setState(() {
                                    _belongsToAssociation = v;
                                    if (v != 'si') {
                                      _selectedAssociation = null;
                                    }
                                  }),
                                  selectedAssociation: _selectedAssociation,
                                  onAssociationChanged: (v) =>
                                      setState(() => _selectedAssociation = v),
                                  onEditPhoto: () => _showImageSourceSheet(),
                                  isUploadingPicture: context.watch<AnimalCubit>().state is AnimalPictureUploading,
                                  localPhotoPath: _localPhotoPath,
                                  photoDeleted: _photoDeleted,
                                  onNameSaved: _saveNameOnly,
                                  identificationTypeOptions: context.watch<CatalogsCubit>().identificationTypes,
                                  associationOptions: context.watch<CatalogsCubit>().registrationAssociations,
                                ),
                                AnimalInfoAdditionalTab(
                                  selectedTemperaments: _selectedTemperaments,
                                  onTemperamentsChanged: (v) =>
                                      setState(() => _selectedTemperaments = v),
                                  allergyController: _allergyController,
                                  diagnoses: _diagnoses,
                                  onDiagnosisChanged: (key, value) =>
                                      setState(() => _diagnoses[key] = value),
                                  otherDiagnosisController:
                                      _otherDiagnosisController,
                                  housingType: _housingType,
                                  onHousingTypeChanged: (v) =>
                                      setState(() => _housingType = v),
                                  purpose: _purpose,
                                  onPurposeChanged: (v) =>
                                      setState(() => _purpose = v),
                                  feedingTypeController: _feedingTypeController,
                                  birthTypeController: _birthTypeController,
                                  birthConditionController:
                                      _birthConditionController,
                                  isBovine: _currentAnimal.family.toLowerCase() == 'bovino',
                                  temperamentOptions: context.watch<CatalogsCubit>().temperaments,
                                  housingTypeOptions: context.watch<CatalogsCubit>().housingTypes,
                                  purposeOptions: context.watch<CatalogsCubit>().animalPurposes,
                                ),
                                AnimalInfoGeneralTab(
                                  animal: _currentAnimal,
                                  onInactivate: () {
                                    // TODO: Implement inactivate
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}

class _BottomShadowClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // Allows the shadow to cast on the left, right, and bottom, but clips the top (y < 0).
    return Rect.fromLTRB(-100, 0, size.width + 100, size.height + 100);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
