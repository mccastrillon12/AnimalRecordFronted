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
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/auth/presentation/widgets/id_selector.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';

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
  String? _selectedApproximateAge;
  late TextEditingController _weightKgController;
  late TextEditingController _colorDescController;
  String? _hasIdentification;
  String? _belongsToAssociation;
  List<String> _selectedAssociations = [];
  String? _selectedIdentificationType;
  final _identificationNumberController = TextEditingController();

  // — Adoption state —
  bool? _isAdopted;
  String? _selectedAdoptionSource;
  late TextEditingController _adoptionPlaceNameController;

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

  // — Saving state —
  bool _isSavingNameOnly = false;
  bool _isInactivating = false;

  // — Original values for change detection —
  late String _originalName;
  late String? _originalReproductiveState;
  late DateTime? _originalBirthDate;
  late String? _originalColorDesc;
  late String? _originalHasIdentification;
  late String? _originalBelongsToAssociation;
  late List<String> _originalSelectedAssociations;
  late String? _originalSelectedIdentificationType;
  late String _originalIdentificationNumber;
  late bool? _originalIsAdopted;
  late String? _originalSelectedAdoptionSource;
  late String _originalAdoptionPlaceName;
  late List<String> _originalTemperaments;
  late String? _originalAllergy;
  late Map<String, bool> _originalDiagnoses;
  late String? _originalHousingType;
  late String? _originalPurpose;
  late String? _originalFeedingType;
  late String? _originalBirthType;
  late String? _originalBirthCondition;
  late String? _originalApproximateAge;

  @override
  void initState() {
    super.initState();
    _currentAnimal = widget.animal;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      FocusManager.instance.primaryFocus?.unfocus();
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
    _unknownExactDate = a.unknownBirthDate;
    _selectedApproximateAge = _approxAgeLabelFromMonths(
      a.approximateAgeMinMonths,
      a.approximateAgeMaxMonths,
    );
    _weightKgController = TextEditingController(
      text: a.weight != null ? a.weight.toString() : '',
    )..addListener(_onFieldChanged);
    _colorDescController = TextEditingController(text: a.colorAndMarkings ?? '')
      ..addListener(_onFieldChanged);
    _hasIdentification = a.hasChip ? 'si' : 'no';
    _selectedIdentificationType = a.identificationType;
    _identificationNumberController.text = a.identificationNumber ?? '';
    _identificationNumberController.addListener(_onFieldChanged);
    _belongsToAssociation = a.isAssociationMember ? 'si' : 'no';
    _selectedAssociations = List<String>.from(a.registrationAssociations ?? []);

    _isAdopted = a.isAdopted;
    _selectedAdoptionSource = a.adoptionSource;
    _adoptionPlaceNameController = TextEditingController(
      text: a.adoptionPlaceName ?? '',
    )..addListener(_onFieldChanged);

    _selectedTemperaments = List<String>.from(a.temperament);
    _allergyController = TextEditingController(text: a.allergies ?? '')
      ..addListener(_onFieldChanged);

    // Set diagnoses from animal data
    for (final d in a.diagnosis) {
      if (_diagnoses.containsKey(d)) {
        _diagnoses[d] = true;
      } else if (d != 'Ninguno') {
        _diagnoses['Otro'] = true;
      }
    }
    // Initialize otherDiagnosisController from otherDiagnosisDetail field
    _otherDiagnosisController = TextEditingController(
      text: a.otherDiagnosisDetail ?? '',
    );
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
    _originalIdentificationNumber = a.identificationNumber ?? '';
    _originalBelongsToAssociation = _belongsToAssociation;
    _originalSelectedAssociations = List<String>.from(_selectedAssociations);
    _originalIsAdopted = _isAdopted;
    _originalSelectedAdoptionSource = _selectedAdoptionSource;
    _originalAdoptionPlaceName = a.adoptionPlaceName ?? '';
    _originalTemperaments = List<String>.from(a.temperament);
    _originalAllergy = a.allergies ?? '';
    _originalDiagnoses = Map<String, bool>.from(_diagnoses);
    _originalHousingType = a.housingType;
    _originalPurpose = a.purpose;
    _originalFeedingType = a.feedingType ?? '';
    _originalBirthType = a.birthType ?? '';
    _originalBirthCondition = a.birthCondition ?? '';
    _originalApproximateAge = _selectedApproximateAge;
  }

  // -- Approximate age helpers --
  static const _approxAgeRanges = <String, (int, int)>{
    '0-6 meses': (0, 6),
    '7-11 meses': (7, 11),
    '1-3 años': (12, 36),
    '4-6 años': (48, 72),
    '7-10 años': (84, 120),
    '11-15 años': (132, 180),
    '16-20 años': (192, 240),
    '21-25 años': (252, 300),
    '+25 años': (300, 1200),
  };

  String? _approxAgeLabelFromMonths(int? min, int? max) {
    if (min == null || max == null) return null;
    for (final entry in _approxAgeRanges.entries) {
      if (entry.value.$1 == min && entry.value.$2 == max) {
        return entry.key;
      }
    }
    return null;
  }

  int? get _approxMin => _approxAgeRanges[_selectedApproximateAge]?.$1;
  int? get _approxMax => _approxAgeRanges[_selectedApproximateAge]?.$2;

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

  String _mapSexToApi(String sex) {
    switch (sex.toLowerCase()) {
      case 'macho':
      case 'male':
        return 'MALE';
      case 'hembra':
      case 'female':
        return 'FEMALE';
      default:
        return sex.toUpperCase();
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
    if (_selectedIdentificationType != _originalSelectedIdentificationType)
      return true;
    if (_identificationNumberController.text.trim() !=
        _originalIdentificationNumber)
      return true;
    if (_belongsToAssociation != _originalBelongsToAssociation) return true;
    if (_selectedAssociations.length != _originalSelectedAssociations.length) return true;
    for (int i = 0; i < _selectedAssociations.length; i++) {
      if (_selectedAssociations[i] != _originalSelectedAssociations[i]) return true;
    }
    if (_isAdopted != _originalIsAdopted) return true;
    if (_selectedAdoptionSource != _originalSelectedAdoptionSource) return true;
    if (_adoptionPlaceNameController.text.trim() != _originalAdoptionPlaceName)
      return true;
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
    if (_selectedApproximateAge != _originalApproximateAge) return true;
    if (_unknownExactDate != _currentAnimal.unknownBirthDate) return true;
    return false;
  }

  void _saveNameOnly(String newName) {
    setState(() {
      _isSavingNameOnly = true;
    });

    final selectedDiagnoses = _diagnoses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final params = UpdateAnimalParams(
      id: _currentAnimal.id,
      name: newName,
      species: _currentAnimal.species,
      breed: _currentAnimal.breed ?? '',
      sex: _mapSexToApi(_currentAnimal.sex ?? ''),
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
      weight: double.tryParse(_weightKgController.text.trim().replaceAll(',', '.')),
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
      identificationType: _hasIdentification == 'si'
          ? _selectedIdentificationType
          : null,
      identificationNumber: _hasIdentification == 'si'
          ? _identificationNumberController.text.trim()
          : null,
      registrationAssociations: _belongsToAssociation == 'si' && _selectedAssociations.isNotEmpty
          ? _selectedAssociations
          : null,
      isAdopted: _isAdopted,
      adoptionSource: _isAdopted == true ? _selectedAdoptionSource : null,
      adoptionPlaceName:
          _isAdopted == true &&
              _adoptionPlaceNameController.text.trim().isNotEmpty
          ? _adoptionPlaceNameController.text.trim()
          : null,
      otherDiagnosisDetail: _diagnoses['Otro'] == true
          ? _otherDiagnosisController.text.trim()
          : null,
      unknownBirthDate: _unknownExactDate,
      approximateAgeMinMonths: _unknownExactDate ? _approxMin : null,
      approximateAgeMaxMonths: _unknownExactDate ? _approxMax : null,
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
      sex: _mapSexToApi(_currentAnimal.sex ?? ''),
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
      weight: double.tryParse(_weightKgController.text.trim().replaceAll(',', '.')),
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
      identificationType: _hasIdentification == 'si'
          ? _selectedIdentificationType
          : null,
      identificationNumber: _hasIdentification == 'si'
          ? _identificationNumberController.text.trim()
          : null,
      registrationAssociations: _belongsToAssociation == 'si' && _selectedAssociations.isNotEmpty
          ? _selectedAssociations
          : null,
      isAdopted: _isAdopted,
      adoptionSource: _isAdopted == true ? _selectedAdoptionSource : null,
      adoptionPlaceName:
          _isAdopted == true &&
              _adoptionPlaceNameController.text.trim().isNotEmpty
          ? _adoptionPlaceNameController.text.trim()
          : null,
      otherDiagnosisDetail: _diagnoses['Otro'] == true
          ? _otherDiagnosisController.text.trim()
          : null,
      unknownBirthDate: _unknownExactDate,
      approximateAgeMinMonths: _unknownExactDate ? _approxMin : null,
      approximateAgeMaxMonths: _unknownExactDate ? _approxMax : null,
    );

    context.read<AnimalCubit>().updateAnimal(params);
  }

  void _onCloseRequested() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: '¿Desea cancelar el proceso?',
          description: 'Perderá los datos diligenciados al momento.',
          confirmLabel: 'Si',
          cancelLabel: 'No',
          width: 325,
          confirmColor: const Color(0xFFFA2844),
          onConfirm: () => Navigator.pop(context),
          onCancel: () {},
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      bool result = false;
      await showDialog(
        context: context,
        builder: (_) => ConfirmDialog(
          title: '¿Desea cancelar el proceso?',
          description: 'Perderá los datos diligenciados al momento.',
          confirmLabel: 'Si',
          cancelLabel: 'No',
          width: 325,
          confirmColor: const Color(0xFFFA2844),
          onConfirm: () {
            result = true;
          },
          onCancel: () {
            result = false;
          },
        ),
      );
      return result;
    }
    return true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _weightKgController.dispose();
    _colorDescController.dispose();
    _identificationNumberController.dispose();
    _adoptionPlaceNameController.dispose();
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
      _originalSelectedIdentificationType = _selectedIdentificationType;
      _originalIdentificationNumber = _identificationNumberController.text
          .trim();
      _originalBelongsToAssociation = _belongsToAssociation;
      _originalSelectedAssociations = List<String>.from(_selectedAssociations);
      _originalIsAdopted = _isAdopted;
      _originalSelectedAdoptionSource = _selectedAdoptionSource;
      _originalAdoptionPlaceName = _adoptionPlaceNameController.text.trim();
      _originalTemperaments = List<String>.from(_selectedTemperaments);
      _originalAllergy = _allergyController.text.trim();
      _originalDiagnoses = Map<String, bool>.from(_diagnoses);
      _originalHousingType = _housingType;
      _originalPurpose = _purpose;
      _originalFeedingType = _feedingTypeController.text.trim();
      _originalBirthType = _birthTypeController.text.trim();
      _originalBirthCondition = _birthConditionController.text.trim();
      _originalApproximateAge = _selectedApproximateAge;
    });
  }

  void _showImageSourceSheet() {
    final picker = ImagePicker();
    final hasExistingPicture =
        _currentAnimal.imageUrl != null || _localPhotoPath != null;

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
                      ErrorDisplay.showSuccess(
                        context,
                        'Foto actualizada exitosamente.',
                      );
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
                      ErrorDisplay.showSuccess(
                        context,
                        'Foto actualizada exitosamente.',
                      );
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
                      ErrorDisplay.showSuccess(
                        context,
                        'Foto eliminada exitosamente.',
                      );
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

  void _showInactivateConfirmation() {
    // Get owner's identification from AuthBloc
    String ownerIdType = 'C.C.';
    String ownerIdNumber = '';
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final rawType = authState.user.identificationType;
      // Map backend codes to IdSelector display values
      const idTypeMap = {
        'CC': 'C.C.',
        'CE': 'C.E.',
        'PAS': 'Pasaporte',
        'C.C.': 'C.C.',
        'C.E.': 'C.E.',
        'Pasaporte': 'Pasaporte',
      };
      ownerIdType = idTypeMap[rawType.toUpperCase()] ??
          idTypeMap[rawType] ??
          (rawType.isNotEmpty ? rawType : 'C.C.');
      ownerIdNumber = authState.user.identificationNumber;
    }

    String? selectedReason;
    final ccController = TextEditingController();
    String? ccError;
    String? reasonError;

    final deactivationReasons = [
      'Fallecimiento del paciente',
      'Error en la creación',
      'Historia duplicada',
      'Cambio a otros sistema de gestión',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: 347,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          // Title
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              '¿Inactivar historia clínica?',
                              style: AppTypography.body3.copyWith(
                                color: AppColors.greyTextos,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description with bold section
                          RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: AppTypography.body6.copyWith(
                                color: AppColors.greyTextos,
                                height: 1.6,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'Al inactivar la historia, no podrás agregar más datos ni realizar más consultas. Esta acción no se puede deshacer, por ende, ',
                                ),
                                TextSpan(
                                  text:
                                      'necesitas solicitarle al propietario su número de identificación para validar la acción.',
                                  style: AppTypography.body6.copyWith(
                                    color: AppColors.greyTextos,
                                    height: 1.6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reason Dropdown (using AppDropdown)
                          AppDropdown<String>(
                            label: 'Seleccionar el motivo para continuar:',
                            hint: 'Seleccionar',
                            value: selectedReason,
                            items: deactivationReasons,
                            itemAsString: (r) => r,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedReason = value;
                                reasonError = null;
                              });
                            },
                            errorText: reasonError,
                            isInline: true,
                            pushContent: true,
                          ),
                          const SizedBox(height: 16),

                          // CC row using IdSelector component
                          IdSelector(
                            customLabel: 'Identificación del propietario',
                            initialIdType: ownerIdType,
                            idTypeEnabled: false,
                            controller: ccController,
                            hintText: 'Número de documento',
                            errorText: ccError,
                            hideErrorText: false,
                            onChanged: (_) {
                              if (ccError != null) {
                                setDialogState(() {
                                  ccError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      40,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: AppTypography.body3.copyWith(
                                      color: const Color(0xFF0072BB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    bool hasError = false;
                                    setDialogState(() {
                                      if (selectedReason == null) {
                                        reasonError = 'Seleccione un motivo';
                                        hasError = true;
                                      }
                                      if (ccController.text.trim() !=
                                          ownerIdNumber) {
                                        ccError =
                                            'El número no coincide con el propietario';
                                        hasError = true;
                                      }
                                    });

                                    if (!hasError) {
                                      Navigator.pop(dialogContext);
                                      _inactivateAnimal(selectedReason!);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFA2844),
                                    foregroundColor: Colors.white,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      40,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                  child: Text(
                                    'Inactivar',
                                    style: AppTypography.body3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // X close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.greyIconos,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _inactivateAnimal(String deactivationReason) {
    setState(() {
      _isInactivating = true;
    });

    final selectedDiagnoses = _diagnoses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final params = UpdateAnimalParams(
      id: _currentAnimal.id,
      name: _currentAnimal.name,
      species: _currentAnimal.species,
      breed: _currentAnimal.breed ?? '',
      sex: _mapSexToApi(_currentAnimal.sex ?? ''),
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
      weight: double.tryParse(_weightKgController.text.trim().replaceAll(',', '.')),
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
      identificationType: _hasIdentification == 'si'
          ? _selectedIdentificationType
          : null,
      identificationNumber: _hasIdentification == 'si'
          ? _identificationNumberController.text.trim()
          : null,
      registrationAssociations: _belongsToAssociation == 'si' && _selectedAssociations.isNotEmpty
          ? _selectedAssociations
          : null,
      isAdopted: _isAdopted,
      adoptionSource: _isAdopted == true ? _selectedAdoptionSource : null,
      adoptionPlaceName:
          _isAdopted == true &&
              _adoptionPlaceNameController.text.trim().isNotEmpty
          ? _adoptionPlaceNameController.text.trim()
          : null,
      otherDiagnosisDetail: _diagnoses['Otro'] == true
          ? _otherDiagnosisController.text.trim()
          : null,
      unknownBirthDate: _unknownExactDate,
      approximateAgeMinMonths: _unknownExactDate ? _approxMin : null,
      approximateAgeMaxMonths: _unknownExactDate ? _approxMax : null,
      isActive: false,
      deactivationReason: deactivationReason,
    );

    context.read<AnimalCubit>().updateAnimal(params);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnimalCubit, AnimalState>(
      listenWhen: (previous, current) {
        return current is AnimalUpdated ||
            current is AnimalPictureUploaded ||
            current is AnimalsLoaded ||
            current is AnimalError;
      },
      listener: (context, state) {
        // Sync approximate age when detail data arrives (AnimalsLoaded from loadAnimalDetails)
        if (state is AnimalsLoaded) {
          try {
            final freshEntity = state.animals.firstWhere(
              (a) => a.id == _currentAnimal.id,
            );
            final freshModel = AnimalModel.fromEntity(freshEntity);
            if (freshModel.unknownBirthDate &&
                freshModel.approximateAgeMinMonths != null &&
                freshModel.approximateAgeMaxMonths != null &&
                _selectedApproximateAge == null) {
              setState(() {
                _currentAnimal = freshModel;
                _unknownExactDate = true;
                _selectedApproximateAge = _approxAgeLabelFromMonths(
                  freshModel.approximateAgeMinMonths,
                  freshModel.approximateAgeMaxMonths,
                );
                _originalApproximateAge = _selectedApproximateAge;
              });
            }
          } catch (_) {}
          return;
        }
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

          if (_isInactivating) {
            ErrorDisplay.showSuccess(
              context,
              'La historia clínica con el ID ${_currentAnimal.code} ha sido inactivada.',
            );
            setState(() {
              _isInactivating = false;
            });
            // Pop back to detail screen so it refreshes with updated state
            _updateOriginalsToCurrent();
            context.read<AnimalCubit>().resetToLoaded();
            return;
          } else if (_isSavingNameOnly) {
            ErrorDisplay.showSuccess(
              context,
              'El nombre ha sido actualizado con éxito. No podrás modificar el nombre nuevamente hasta pasados 30 días.',
            );
            setState(() {
              _isSavingNameOnly = false;
            });
          } else {
            ErrorDisplay.showSuccess(
              context,
              'Información guardada exitosamente.',
            );
          }

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
          if (_isSavingNameOnly) {
            setState(() {
              _isSavingNameOnly = false;
            });
          }
          if (_isInactivating) {
            setState(() {
              _isInactivating = false;
            });
          }
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
                freshModel.imageUrl != _currentAnimal.imageUrl ||
                freshModel.unknownBirthDate !=
                    _currentAnimal.unknownBirthDate ||
                freshModel.approximateAgeMinMonths !=
                    _currentAnimal.approximateAgeMinMonths ||
                freshModel.approximateAgeMaxMonths !=
                    _currentAnimal.approximateAgeMaxMonths) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentAnimal = freshModel;
                    // Re-sync approximate age state when detail data arrives
                    if (freshModel.unknownBirthDate &&
                        freshModel.approximateAgeMinMonths != null &&
                        freshModel.approximateAgeMaxMonths != null &&
                        _selectedApproximateAge == null) {
                      _unknownExactDate = true;
                      _selectedApproximateAge = _approxAgeLabelFromMonths(
                        freshModel.approximateAgeMinMonths,
                        freshModel.approximateAgeMaxMonths,
                      );
                      _originalApproximateAge = _selectedApproximateAge;
                    }
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
          child: WillPopScope(
            onWillPop: _onWillPop,
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
                                onPressed: _onCloseRequested,
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
                                labelPadding: EdgeInsets.zero,
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
                              padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                              bottomChild:
                                  _tabController.index == 2 &&
                                      _currentAnimal.isActive
                                  ? OutlinedButton(
                                      onPressed: () {
                                        _showInactivateConfirmation();
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
                                  : (_hasChanges && _currentAnimal.isActive
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
                                        setState(() {
                                          _unknownExactDate = v;
                                          if (v) {
                                            _birthDate = null;
                                          } else {
                                            _selectedApproximateAge = null;
                                          }
                                        }),
                                    selectedApproximateAge:
                                        _selectedApproximateAge,
                                    onApproximateAgeChanged: (v) => setState(
                                      () => _selectedApproximateAge = v,
                                    ),
                                    weightKgController: _weightKgController,
                                    colorDescController: _colorDescController,
                                    hasIdentification: _hasIdentification,
                                    onHasIdentificationChanged: (v) =>
                                        setState(() {
                                          _hasIdentification = v;
                                          if (v != 'si') {
                                            _selectedIdentificationType = null;
                                          }
                                        }),
                                    selectedIdentificationType:
                                        _selectedIdentificationType,
                                    onIdentificationTypeChanged: (v) =>
                                        setState(
                                          () => _selectedIdentificationType = v,
                                        ),
                                    identificationNumberController:
                                        _identificationNumberController,
                                    belongsToAssociation: _belongsToAssociation,
                                    onBelongsToAssociationChanged: (v) =>
                                        setState(() {
                                          _belongsToAssociation = v;
                                          if (v != 'si') {
                                            _selectedAssociations = [];
                                          }
                                        }),
                                    selectedAssociations: _selectedAssociations,
                                    onAssociationsChanged: (v) => setState(
                                      () => _selectedAssociations = v,
                                    ),
                                    onAddAssociation: (name) {
                                      setState(() {
                                        if (!_selectedAssociations.contains(name)) {
                                          _selectedAssociations = [..._selectedAssociations, name];
                                        }
                                      });
                                    },
                                    onEditPhoto: () => _showImageSourceSheet(),
                                    isUploadingPicture:
                                        context.watch<AnimalCubit>().state
                                            is AnimalPictureUploading,
                                    localPhotoPath: _localPhotoPath,
                                    photoDeleted: _photoDeleted,
                                    onNameSaved: _saveNameOnly,
                                    isAdopted: _isAdopted,
                                    onIsAdoptedChanged: (v) => setState(() {
                                      _isAdopted = v;
                                      if (v == false) {
                                        _selectedAdoptionSource = null;
                                        _adoptionPlaceNameController.clear();
                                      }
                                    }),
                                    selectedAdoptionSource:
                                        _selectedAdoptionSource,
                                    onAdoptionSourceChanged: (v) => setState(
                                      () => _selectedAdoptionSource = v,
                                    ),
                                    adoptionPlaceNameController:
                                        _adoptionPlaceNameController,
                                    identificationTypeOptions: context
                                        .watch<CatalogsCubit>()
                                        .identificationTypes,
                                    associationOptions: context
                                        .watch<CatalogsCubit>()
                                        .registrationAssociations,
                                    adoptionSourceOptions: context
                                        .watch<CatalogsCubit>()
                                        .adoptionSources,
                                    readOnly: !_currentAnimal.isActive,
                                  ),
                                  AnimalInfoAdditionalTab(
                                    selectedTemperaments: _selectedTemperaments,
                                    onTemperamentsChanged: (v) => setState(
                                      () => _selectedTemperaments = v,
                                    ),
                                    allergyController: _allergyController,
                                    diagnoses: _diagnoses,
                                    onDiagnosisChanged: (key, value) {
                                      setState(() {
                                        _diagnoses[key] = value;
                                        
                                        if (value) {
                                          if (key == 'Ninguno/Desconocido') {
                                            // Deselect all others
                                            for (final k in _diagnoses.keys) {
                                              if (k != 'Ninguno/Desconocido') {
                                                _diagnoses[k] = false;
                                              }
                                            }
                                            _otherDiagnosisController.clear();
                                          } else {
                                            // Deselect Ninguno/Desconocido
                                            _diagnoses['Ninguno/Desconocido'] = false;
                                          }
                                        }

                                        if (key == 'Otro' && !value) {
                                          _otherDiagnosisController.clear();
                                        }
                                      });
                                    },
                                    otherDiagnosisController:
                                        _otherDiagnosisController,
                                    housingType: _housingType,
                                    onHousingTypeChanged: (v) =>
                                        setState(() => _housingType = v),
                                    purpose: _purpose,
                                    onPurposeChanged: (v) =>
                                        setState(() => _purpose = v),
                                    feedingTypeController:
                                        _feedingTypeController,
                                    birthTypeController: _birthTypeController,
                                    birthConditionController:
                                        _birthConditionController,
                                    isBovine:
                                        _currentAnimal.family.toLowerCase() ==
                                        'bovino',
                                    temperamentOptions: context
                                        .watch<CatalogsCubit>()
                                        .temperaments,
                                    housingTypeOptions: context
                                        .watch<CatalogsCubit>()
                                        .housingTypes,
                                    purposeOptions: context
                                        .watch<CatalogsCubit>()
                                        .animalPurposes,
                                    readOnly: !_currentAnimal.isActive,
                                  ),
                                  AnimalInfoGeneralTab(
                                    animal: _currentAnimal,
                                    onInactivate: () {
                                      _showInactivateConfirmation();
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
