import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/widgets/layout/base_modal_card.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import 'package:animal_record/core/widgets/buttons/custom_checkbox.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/inputs/custom_date_field.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';

import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/catalogs/domain/entities/species_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/breed_entity.dart';
import 'package:animal_record/features/catalogs/domain/entities/catalog_item_entity.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_cubit.dart';
import 'package:animal_record/features/catalogs/presentation/cubit/catalogs_state.dart';

/// Opens the AnimalCreationModal as an overlay dialog on the current screen.
void showAnimalCreationModal(BuildContext context) {
  final animalCubit = context.read<AnimalCubit>();
  showBaseModalCard(
    context: context,
    builder: (dialogContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: animalCubit),
        BlocProvider.value(value: sl<CatalogsCubit>()..loadSpecies()),
      ],
      child: const AnimalCreationModal(),
    ),
  );
}

class AnimalCreationModal extends StatefulWidget {
  const AnimalCreationModal({super.key});

  @override
  State<AnimalCreationModal> createState() => _AnimalCreationModalState();
}

class _AnimalCreationModalState extends State<AnimalCreationModal> {
  int _currentStep = 1;
  static const int _totalSteps = 3;

  // — Step 1 state —
  SpeciesEntity? _selectedSpecies;

  // — Step 2 state —
  final _nameController = TextEditingController();
  String? _selectedBreed;
  String? _selectedSex;
  String? _reproductiveState;
  DateTime? _birthDate;
  bool _unknownExactDate = false;
  String? _selectedApproximateAge;
  final _weightKgController = TextEditingController();
  final _weightLbController = TextEditingController();
  String? _weightErrorText;
  final _colorDescController = TextEditingController();
  String? _hasIdentification;
  String? _selectedIdentificationType;
  final _identificationNumberController = TextEditingController();
  String? _belongsToAssociation;
  String? _selectedAssociation;
  String? _selectedPhotoPath;
  String? _selectedPurpose;
  bool? _isAdopted;
  String? _selectedAdoptionSource;
  final _adoptionPlaceNameController = TextEditingController();

  // — Step 3 state —
  List<String> _selectedTemperaments = [];
  final _allergyController = TextEditingController();
  final Map<String, bool> _diagnoses = {
    'Ninguno/Desconocido': false,
    'Mielopatía degenerativa': false,
    'Displasia de cadera': false,
    'Leishmaniasis': false,
    'Otro': false,
  };
  final _otherDiagnosisController = TextEditingController();
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _otherDiagnosisController.addListener(_onOtherDiagnosisChanged);
    _weightKgController.addListener(_onWeightKgChanged);
    _weightLbController.addListener(_onWeightLbChanged);
  }

  void _onOtherDiagnosisChanged() {
    // Trigger rebuild so _isStep3Valid re-evaluates when the user types in "¿Cuál?"
    setState(() {});
  }

  void _onWeightKgChanged() {
    if (_isConverting) return;
    _isConverting = true;
    final text = _weightKgController.text.trim();
    if (text.isEmpty) {
      _weightLbController.clear();
    } else {
      final kg = double.tryParse(text.replaceAll(',', '.'));
      if (kg != null) {
        final lb = (kg * 2.20462);
        final lbStr = lb.toStringAsFixed(2).replaceAll('.', ',');
        _weightLbController.text = lbStr;
      }
    }
    _isConverting = false;
  }

  void _onWeightLbChanged() {
    if (_isConverting) return;
    _isConverting = true;
    final text = _weightLbController.text.trim();
    if (text.isEmpty) {
      _weightKgController.clear();
    } else {
      final lb = double.tryParse(text.replaceAll(',', '.'));
      if (lb != null) {
        final kg = (lb / 2.20462);
        final kgStr = kg.toStringAsFixed(2).replaceAll('.', ',');
        _weightKgController.text = kgStr;
      }
    }
    _isConverting = false;
  }

  @override
  void dispose() {
    _otherDiagnosisController.removeListener(_onOtherDiagnosisChanged);
    _weightKgController.removeListener(_onWeightKgChanged);
    _weightLbController.removeListener(_onWeightLbChanged);
    _nameController.dispose();
    _weightKgController.dispose();
    _weightLbController.dispose();
    _colorDescController.dispose();
    _identificationNumberController.dispose();
    _allergyController.dispose();
    _otherDiagnosisController.dispose();
    _adoptionPlaceNameController.dispose();
    super.dispose();
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep == 2) {
      _resetForm();
    } else if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _goNext() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  void _onFamilySelected(SpeciesEntity species) {
    setState(() {
      _selectedSpecies = species;
      _selectedBreed = null;
      _selectedPurpose = null;
      _currentStep = 2;
    });
    final catalogsCubit = context.read<CatalogsCubit>();
    // Load breeds without purpose filter initially only if not bovino
    if (species.name.toLowerCase() != 'bovino') {
      catalogsCubit.loadBreeds(species.id);
    }
    // Load all animal-specific catalogs filtered by species
    catalogsCubit.loadAnimalCatalogs(speciesId: species.id);
  }

  void _onPurposeChanged(String? purposeName) {
    final cubit = context.read<CatalogsCubit>();
    // Find the purpose ID from the catalog items
    String? purposeId;
    if (purposeName != null) {
      final match = cubit.animalPurposes.where((p) => p.name == purposeName);
      if (match.isNotEmpty) purposeId = match.first.id;
    }
    
    final isBovino = _selectedSpecies != null &&
        _selectedSpecies!.name.toLowerCase() == 'bovino';

    setState(() {
      _selectedPurpose = purposeName;
      if (isBovino) {
        _selectedBreed = null; // Reset breed when purpose changes
      }
    });
    
    // Reload breeds filtered by purpose only for bovinos
    if (isBovino) {
      cubit.loadBreeds(_selectedSpecies!.id, purposeId: purposeId);
    }
  }

  // =========================================================================
  // Validation
  // =========================================================================

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

  bool get _isStep2Valid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedBreed != null &&
        _selectedSex != null &&
        _reproductiveState != null &&
        (_birthDate != null || _unknownExactDate) &&
        (!_unknownExactDate || _selectedApproximateAge != null) &&
        _hasIdentification != null &&
        _belongsToAssociation != null &&
        (_belongsToAssociation != 'si' || _selectedAssociation != null) &&
        _isAdopted != null &&
        (_isAdopted == false || _selectedAdoptionSource != null);
  }

  bool get _isStep3Valid {
    return _selectedTemperaments.isNotEmpty && _diagnoses.values.any((v) => v) &&
        (_diagnoses['Otro'] != true || _otherDiagnosisController.text.trim().isNotEmpty);
  }

  /// Returns true if the user has filled in at least one field after step 1.
  bool get _hasAnyFieldFilled {
    return _nameController.text.trim().isNotEmpty ||
        _selectedBreed != null ||
        _selectedSex != null ||
        _reproductiveState != null ||
        _birthDate != null ||
        _unknownExactDate ||
        _weightKgController.text.trim().isNotEmpty ||
        _weightLbController.text.trim().isNotEmpty ||
        _colorDescController.text.trim().isNotEmpty ||
        _hasIdentification != null ||
        _selectedIdentificationType != null ||
        _identificationNumberController.text.trim().isNotEmpty ||
        _belongsToAssociation != null ||
        _selectedAssociation != null ||
        _selectedPhotoPath != null ||
        _selectedPurpose != null ||
        _isAdopted != null ||
        _selectedAdoptionSource != null ||
        _adoptionPlaceNameController.text.trim().isNotEmpty ||
        _selectedTemperaments.isNotEmpty ||
        _allergyController.text.trim().isNotEmpty ||
        _diagnoses.values.any((v) => v) ||
        _otherDiagnosisController.text.trim().isNotEmpty;
  }

  void _onCloseRequested() {
    if (_hasAnyFieldFilled) {
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

  // =========================================================================
  // Build params & save
  // =========================================================================

  Future<CreateAnimalParams> _buildParams() async {
    final ownerId = await sl<TokenStorage>().getUserId() ?? '';
    final uuid = const Uuid();

    // Enviar todos los valores tal como se seleccionaron en español (sin mayúsculas forzadas ni mapeos al inglés).
    // Para el diagnóstico, solo extraemos los que están marcados. En caso de estar vacío enviamos "Ninguno".
    final selectedDiagnoses = _diagnoses.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return CreateAnimalParams(
      id: uuid.v4(),
      name: _nameController.text.trim(),
      species: _mapSpeciesToApi(_selectedSpecies!.name),
      breed: _selectedBreed!,
      sex: _selectedSex == 'macho' ? 'MALE' : 'FEMALE',
      reproductiveStatus: _reproductiveState!, // ej: "esterilizado"
      birthdate: _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      hasChip: _hasIdentification == 'si',
      isAssociationMember: _belongsToAssociation == 'si',
      temperament: _selectedTemperaments.isEmpty
          ? ['Desconocido']
          : _selectedTemperaments,
      diagnosis: selectedDiagnoses.isEmpty ? ['Ninguno'] : selectedDiagnoses,
      otherDiagnosisDetail: _diagnoses['Otro'] == true
          ? _otherDiagnosisController.text.trim()
          : null,
      ownerId: ownerId,
      weight: double.tryParse(_weightKgController.text.trim().replaceAll(',', '.')),
      colorAndMarkings: _colorDescController.text.trim().isNotEmpty
          ? _colorDescController.text.trim()
          : null,
      allergies: _allergyController.text.trim().isNotEmpty
          ? _allergyController.text.trim()
          : null,
      purpose: _selectedPurpose,
      identificationType: _hasIdentification == 'si'
          ? _selectedIdentificationType
          : null,
      identificationNumber: _hasIdentification == 'si'
          ? _identificationNumberController.text.trim()
          : null,
      registrationAssociation: _belongsToAssociation == 'si'
          ? _selectedAssociation
          : null,
      isAdopted: _isAdopted,
      adoptionSource: _isAdopted == true ? _selectedAdoptionSource : null,
      adoptionPlaceName: _isAdopted == true && _adoptionPlaceNameController.text.trim().isNotEmpty
          ? _adoptionPlaceNameController.text.trim()
          : null,
      unknownBirthDate: _unknownExactDate,
      approximateAgeMinMonths: _unknownExactDate ? _getApproxMin() : null,
      approximateAgeMaxMonths: _unknownExactDate ? _getApproxMax() : null,
    );
  }

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

  int? _getApproxMin() => _approxAgeRanges[_selectedApproximateAge]?.$1;
  int? _getApproxMax() => _approxAgeRanges[_selectedApproximateAge]?.$2;

  Future<void> _saveAnimal({bool addAnother = false}) async {
    final params = await _buildParams();
    if (!mounted) return;
    context.read<AnimalCubit>().createAnimal(params);
    // addAnother flag is handled via BlocListener
    _pendingAddAnother = addAnother;
  }

  bool _pendingAddAnother = false;

  void _resetForm() {
    setState(() {
      _currentStep = 1;
      _selectedSpecies = null;
      _nameController.clear();
      _selectedBreed = null;
      _selectedSex = null;
      _reproductiveState = null;
      _birthDate = null;
      _unknownExactDate = false;
      _selectedApproximateAge = null;
      _weightKgController.clear();
      _weightLbController.clear();
      _colorDescController.clear();
      _hasIdentification = null;
      _selectedIdentificationType = null;
      _identificationNumberController.clear();
      _belongsToAssociation = null;
      _selectedAssociation = null;
      _selectedPhotoPath = null;
      _selectedPurpose = null;
      _isAdopted = null;
      _selectedAdoptionSource = null;
      _adoptionPlaceNameController.clear();
      _selectedTemperaments = [];
      _allergyController.clear();
      _diagnoses.updateAll((key, value) => false);
      _otherDiagnosisController.clear();
    });
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 1:
        return 'Familia';
      case 2:
        return 'Info. del animal';
      case 3:
        return 'Info. Adicional';
      default:
        return '';
    }
  }

  Widget _buildSubtitle() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _stepSubtitle,
            style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
          ),
          TextSpan(
            text: ' - $_currentStep de $_totalSteps',
            style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnimalCubit, AnimalState>(
      listener: (context, state) {
        if (state is AnimalCreated) {
          // If a photo was selected during creation, upload it now
          // but DON'T close the modal yet — wait for upload to finish
          if (_selectedPhotoPath != null) {
            final photoPath = _selectedPhotoPath!;
            _selectedPhotoPath = null;
            context.read<AnimalCubit>().updateProfilePicture(
              state.animal.id,
              photoPath,
            );
            // Modal stays open showing the loading state
          } else {
            // No photo — close immediately
            if (_pendingAddAnother) {
              _pendingAddAnother = false;
              context.read<AnimalCubit>().resetToLoaded();
              _resetForm();
              ErrorDisplay.showSuccess(context, '¡${state.animal.name} ha sido agregado con éxito!');
            } else {
              context.read<AnimalCubit>().resetToLoaded();
              final animalModel = AnimalModel.fromEntity(state.animal);
              final nav = Navigator.of(context);
              nav.pop();
              nav.pushNamed(AppRoutes.animalDetail, arguments: animalModel);
              ErrorDisplay.showSuccess(context, '¡${state.animal.name} ha sido agregado con éxito!');
            }
          }
        } else if (state is AnimalPictureUploaded) {
          // Photo upload finished after creation — now close/reset
          if (_pendingAddAnother) {
            _pendingAddAnother = false;
            context.read<AnimalCubit>().resetToLoaded();
            _resetForm();
            ErrorDisplay.showSuccess(context, '¡${state.animal.name} ha sido agregado con éxito!');
          } else {
            context.read<AnimalCubit>().resetToLoaded();
            final animalModel = AnimalModel.fromEntity(state.animal);
            final nav = Navigator.of(context);
            nav.pop();
            nav.pushNamed(AppRoutes.animalDetail, arguments: animalModel);
            ErrorDisplay.showSuccess(context, '¡${state.animal.name} ha sido agregado con éxito!');
          }
        } else if (state is AnimalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.secondaryCoral,
            ),
          );
          context.read<AnimalCubit>().resetToLoaded();
        }
      },
      child: BaseModalCard(
        title: 'Agregar animal',
        subtitle: _buildSubtitle(),
        showBackButton: _currentStep > 1,
        onBack: _goBack,
        onClose: _onCloseRequested,
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return BlocBuilder<CatalogsCubit, CatalogsState>(
          builder: (context, catalogState) {
            final cubit = context.watch<CatalogsCubit>();
            final isLoading = catalogState is CatalogsLoading;
            final species = cubit.species
                .where((s) => s.name.toLowerCase() != 'porcino')
                .toList();
            return _FamilySelectionStep(
              species: species,
              isLoading: isLoading,
              onFamilySelected: _onFamilySelected,
            );
          },
        );
      case 2:
        return BlocBuilder<CatalogsCubit, CatalogsState>(
          builder: (context, catalogState) {
            final cubit = context.watch<CatalogsCubit>();
            final breeds = cubit.breeds;
            final breedsLoading = catalogState is BreedsLoading;
            return _AnimalInfoStep(
              selectedSpecies: _selectedSpecies!,
              nameController: _nameController,
              selectedBreed: _selectedBreed,
              onBreedChanged: (v) => setState(() => _selectedBreed = v),
              breeds: breeds,
              breedsLoading: breedsLoading,
              selectedSex: _selectedSex,
              onSexChanged: (v) => setState(() => _selectedSex = v),
              reproductiveState: _reproductiveState,
              onReproductiveStateChanged: (v) =>
                  setState(() => _reproductiveState = v),
              birthDate: _birthDate,
              onBirthDateChanged: (v) => setState(() => _birthDate = v),
              unknownExactDate: _unknownExactDate,
              onUnknownExactDateChanged: (v) => setState(() {
                _unknownExactDate = v;
                if (v) {
                  _birthDate = null;
                } else {
                  _selectedApproximateAge = null;
                }
              }),
              selectedApproximateAge: _selectedApproximateAge,
              onApproximateAgeChanged: (v) => setState(() => _selectedApproximateAge = v),
              weightKgController: _weightKgController,
              weightLbController: _weightLbController,
              weightErrorText: _weightErrorText,
              onWeightErrorChanged: (error) => setState(() => _weightErrorText = error),
              colorDescController: _colorDescController,
              hasIdentification: _hasIdentification,
              onHasIdentificationChanged: (v) => setState(() {
                _hasIdentification = v;
                if (v != 'si') {
                  _selectedIdentificationType = null;
                  _identificationNumberController.clear();
                }
              }),
              selectedIdentificationType: _selectedIdentificationType,
              onIdentificationTypeChanged: (v) =>
                  setState(() => _selectedIdentificationType = v),
              identificationNumberController: _identificationNumberController,
              belongsToAssociation: _belongsToAssociation,
              onBelongsToAssociationChanged: (v) => setState(() {
                _belongsToAssociation = v;
                if (v != 'si') _selectedAssociation = null;
              }),
              selectedAssociation: _selectedAssociation,
              onAssociationChanged: (val) =>
                  setState(() => _selectedAssociation = val),
              isAdopted: _isAdopted,
              onIsAdoptedChanged: (val) => setState(() {
                _isAdopted = val;
                if (val == false) {
                  _selectedAdoptionSource = null;
                  _adoptionPlaceNameController.clear();
                }
              }),
              selectedAdoptionSource: _selectedAdoptionSource,
              onAdoptionSourceChanged: (val) =>
                  setState(() => _selectedAdoptionSource = val),
              adoptionPlaceNameController: _adoptionPlaceNameController,
              adoptionSourceOptions: cubit.adoptionSources,
              isValid: _isStep2Valid,
              onContinue: _isStep2Valid ? _goNext : null,
              selectedPhotoPath: _selectedPhotoPath,
              onPhotoSelected: (path) =>
                  setState(() => _selectedPhotoPath = path),
              onPhotoRemoved: () => setState(() => _selectedPhotoPath = null),
              associationOptions: cubit.registrationAssociations,
              selectedPurpose: _selectedPurpose,
              onPurposeChanged: _onPurposeChanged,
              purposeOptions: cubit.animalPurposes,
              identificationTypeOptions: cubit.identificationTypes,
            );
          },
        );
      case 3:
        return BlocBuilder<AnimalCubit, AnimalState>(
          builder: (context, state) {
            final isLoading = state is AnimalCreating;
            return _AdditionalInfoStep(
              selectedTemperaments: _selectedTemperaments,
              onTemperamentsChanged: (v) =>
                  setState(() => _selectedTemperaments = v),
              allergyController: _allergyController,
              diagnoses: _diagnoses,
              otherDiagnosisController: _otherDiagnosisController,
              onDiagnosisChanged: (key, value) {
                setState(() {
                  // Single-select: deselect all others
                  for (final k in _diagnoses.keys) {
                    _diagnoses[k] = false;
                  }
                  _diagnoses[key] = value;
                  if (key != 'Otro' || !value) {
                    _otherDiagnosisController.clear();
                  }
                });
              },
              isValid: _isStep3Valid,
              isLoading: isLoading,
              onSave: _isStep3Valid && !isLoading ? () => _saveAnimal() : null,
              onSaveAndAddAnother: _isStep3Valid && !isLoading
                  ? () => _saveAnimal(addAnother: true)
                  : null,
              temperamentOptions: context.watch<CatalogsCubit>().temperaments,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// STEP 1 — Family Selection
// =============================================================================

class _FamilySelectionStep extends StatelessWidget {
  final List<SpeciesEntity> species;
  final bool isLoading;
  final ValueChanged<SpeciesEntity> onFamilySelected;

  const _FamilySelectionStep({
    required this.species,
    required this.isLoading,
    required this.onFamilySelected,
  });

  /// Map species name to an SVG asset path.
  static String _iconForSpecies(String name) {
    switch (name.toLowerCase()) {
      case 'felino':
        return 'assets/illustrations/cat_icon.svg';
      case 'canino':
        return 'assets/illustrations/dog_icon.svg';
      case 'bovino':
        return 'assets/illustrations/bovino_icon.svg';
      case 'equino':
        return 'assets/illustrations/equino_icon.svg';
      default:
        // Fallback for species without a dedicated icon (e.g. Porcino)
        return 'assets/illustrations/bovino_icon.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Elige a qué familia pertenece tu animal',
            style: AppTypography.body4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: 170,
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: species
                  .map(
                    (s) => _FamilyCard(
                      name: s.name,
                      iconAsset: _iconForSpecies(s.name),
                      onTap: () => onFamilySelected(s),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final String name;
  final String iconAsset;
  final VoidCallback onTap;

  const _FamilyCard({
    required this.name,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyBordes, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: AppSpacing.iconSizeMedium,
              height: 35,
            ),
            const SizedBox(height: 2),
            Text(name, style: AppTypography.body4),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 2 — Animal Info
// =============================================================================

class _AnimalInfoStep extends StatelessWidget {
  final SpeciesEntity selectedSpecies;
  final TextEditingController nameController;
  final String? selectedBreed;
  final ValueChanged<String?> onBreedChanged;
  final List<BreedEntity> breeds;
  final bool breedsLoading;
  final String? selectedSex;
  final ValueChanged<String?> onSexChanged;
  final String? reproductiveState;
  final ValueChanged<String?> onReproductiveStateChanged;
  final DateTime? birthDate;
  final ValueChanged<DateTime> onBirthDateChanged;
  final bool unknownExactDate;
  final ValueChanged<bool> onUnknownExactDateChanged;
  final String? selectedApproximateAge;
  final ValueChanged<String?> onApproximateAgeChanged;
  final TextEditingController weightKgController;
  final TextEditingController weightLbController;
  final String? weightErrorText;
  final ValueChanged<String?> onWeightErrorChanged;
  final TextEditingController colorDescController;
  final String? hasIdentification;
  final ValueChanged<String?> onHasIdentificationChanged;
  final String? selectedIdentificationType;
  final ValueChanged<String?> onIdentificationTypeChanged;
  final TextEditingController identificationNumberController;
  final String? belongsToAssociation;
  final ValueChanged<String?> onBelongsToAssociationChanged;
  final String? selectedAssociation;
  final ValueChanged<String?> onAssociationChanged;
  final bool? isAdopted;
  final ValueChanged<bool?> onIsAdoptedChanged;
  final String? selectedAdoptionSource;
  final ValueChanged<String?> onAdoptionSourceChanged;
  final TextEditingController adoptionPlaceNameController;
  final bool isValid;
  final VoidCallback? onContinue;
  final String? selectedPhotoPath;
  final ValueChanged<String> onPhotoSelected;
  final VoidCallback onPhotoRemoved;

  // Dynamic catalog data from API
  final List<CatalogItemEntity> associationOptions;
  final String? selectedPurpose;
  final ValueChanged<String?> onPurposeChanged;
  final List<CatalogItemEntity> purposeOptions;
  final List<CatalogItemEntity> identificationTypeOptions;
  final List<CatalogItemEntity> adoptionSourceOptions;

  const _AnimalInfoStep({
    required this.selectedSpecies,
    required this.nameController,
    required this.selectedBreed,
    required this.onBreedChanged,
    required this.breeds,
    required this.breedsLoading,
    required this.selectedSex,
    required this.onSexChanged,
    required this.reproductiveState,
    required this.onReproductiveStateChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.unknownExactDate,
    required this.onUnknownExactDateChanged,
    this.selectedApproximateAge,
    required this.onApproximateAgeChanged,
    required this.weightKgController,
    required this.weightLbController,
    this.weightErrorText,
    required this.onWeightErrorChanged,
    required this.colorDescController,
    required this.hasIdentification,
    required this.onHasIdentificationChanged,
    this.selectedIdentificationType,
    required this.onIdentificationTypeChanged,
    required this.identificationNumberController,
    required this.belongsToAssociation,
    required this.onBelongsToAssociationChanged,
    required this.selectedAssociation,
    required this.onAssociationChanged,
    required this.isAdopted,
    required this.onIsAdoptedChanged,
    required this.selectedAdoptionSource,
    required this.onAdoptionSourceChanged,
    required this.adoptionPlaceNameController,
    required this.isValid,
    required this.onContinue,
    this.selectedPhotoPath,
    required this.onPhotoSelected,
    required this.onPhotoRemoved,
    this.associationOptions = const [],
    this.selectedPurpose,
    required this.onPurposeChanged,
    this.purposeOptions = const [],
    this.identificationTypeOptions = const [],
    this.adoptionSourceOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: Stack(
            children: [
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppColors.greyDelineante,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned.fill(
                child: RawScrollbar(
                  thumbColor: AppColors.primaryIndigo,
                  radius: const Radius.circular(AppBorders.radiusSmall),
                  thickness: 2,
                  thumbVisibility: true,
                  interactive: false,
                  crossAxisMargin: 16,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Family label
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Familia - ',
                                style: AppTypography.body3,
                              ),
                              TextSpan(
                                text: selectedSpecies.name,
                                style: AppTypography.body4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Photo area
                        _buildPhotoArea(context),
                        const SizedBox(height: AppSpacing.m),

                        // Name
                        CustomTextField(
                          label: 'Nombre',
                          controller: nameController,
                          maxLength: 50,
                          textCapitalization: TextCapitalization.sentences,
                          strictValidation: true,
                          allowPattern: RegExp(r'^[a-zA-ZÀ-ÿ0-9\s.,´]+$'),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Productive purpose
                        AppDropdown<String>(
                          label: selectedSpecies.name.toLowerCase() == 'bovino'
                              ? 'Propósito productivo'
                              : 'Propósito',
                          hint: 'Buscar o escribir',
                          value: selectedPurpose,
                          searchable: true,
                          isInline: true,
                          items: purposeOptions.map((p) => p.name).toList(),
                          itemAsString: (name) => name,
                          onChanged: onPurposeChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Breed dropdown
                        AppDropdown<String>(
                          label: 'Raza',
                          hint: breedsLoading
                              ? 'Cargando razas...'
                              : 'Buscar o escribir',
                          value: selectedBreed,
                          searchable: true,
                          isInline: true,
                          enabled: (!breedsLoading && breeds.isNotEmpty) &&
                              (selectedSpecies.name.toLowerCase() != 'bovino' || selectedPurpose != null),
                          items: breeds.map((b) => b.name).toList(),
                          itemAsString: (name) => name,
                          onChanged: onBreedChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Sex
                        Text('Sexo', style: AppTypography.body6),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            CustomRadioButton<String>(
                              value: 'macho',
                              groupValue: selectedSex,
                              label: 'Macho',
                              onChanged: onSexChanged,
                            ),
                            const SizedBox(width: AppSpacing.xxxl),
                            CustomRadioButton<String>(
                              value: 'hembra',
                              groupValue: selectedSex,
                              label: 'Hembra',
                              onChanged: onSexChanged,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Reproductive state
                        Text('Estado reproductivo', style: AppTypography.body6),
                        const SizedBox(height: AppSpacing.xs),
                        CustomRadioButton<String>(
                          value: 'esterilizado',
                          groupValue: reproductiveState,
                          label: 'Esterilizado',
                          onChanged: onReproductiveStateChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        CustomRadioButton<String>(
                          value: 'no_esterilizado',
                          groupValue: reproductiveState,
                          label: 'No esterilizado',
                          onChanged: onReproductiveStateChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        CustomRadioButton<String>(
                          value: 'desconocido',
                          groupValue: reproductiveState,
                          label: 'Desconocido',
                          onChanged: onReproductiveStateChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Birth date
                        CustomDateField(
                          label: 'Fecha de nacimiento',
                          value: birthDate,
                          onChanged: onBirthDateChanged,
                          enabled: !unknownExactDate,
                          showAge: true,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Unknown date toggle
                        _buildToggle(
                          label: 'No sé la fecha exacta',
                          value: unknownExactDate,
                          onChanged: onUnknownExactDateChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Approximate age dropdown (only when unknown date is checked)
                        if (unknownExactDate) ...[
                          AppDropdown<String>(
                            label: 'Edad aproximada',
                            hint: 'Seleccionar',
                            value: selectedApproximateAge,
                            isInline: true,
                            items: const [
                              '0-6 meses',
                              '7-11 meses',
                              '1-3 años',
                              '4-6 años',
                              '7-10 años',
                              '11-15 años',
                              '16-20 años',
                              '21-25 años',
                              '+25 años',
                            ],
                            itemAsString: (v) => v,
                            onChanged: onApproximateAgeChanged,
                            preserveOrder: true,
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        // Weight
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Peso ',
                                style: AppTypography.body6,
                              ),
                              TextSpan(
                                text: '(Opcional)',
                                style: AppTypography.body6.copyWith(
                                  color: AppColors.greyBordes,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.inputTopPadding),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: '',
                                    hint: '- kg',
                                    controller: weightKgController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    maxLength: 7,
                                    inputFormatters: [
                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                        return newValue.copyWith(
                                          text: newValue.text.replaceAll('.', ','),
                                        );
                                      }),
                                    ],
                                    strictValidation: true,
                                    allowPattern: RegExp(r'^[0-9,]+$'),
                                    patternErrorMessage: 'Solo se permiten números y comas',
                                    hideErrorText: true,
                                    onErrorChanged: (error) {
                                      if (weightErrorText != error) {
                                        onWeightErrorChanged(error);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: CustomTextField(
                                    label: '',
                                    hint: '- lb',
                                    controller: weightLbController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    maxLength: 7,
                                    inputFormatters: [
                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                        return newValue.copyWith(
                                          text: newValue.text.replaceAll('.', ','),
                                        );
                                      }),
                                    ],
                                    strictValidation: true,
                                    allowPattern: RegExp(r'^[0-9,]+$'),
                                    patternErrorMessage: 'Solo se permiten números y comas',
                                    hideErrorText: true,
                                    onErrorChanged: (error) {
                                      if (weightErrorText != error) {
                                        onWeightErrorChanged(error);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (weightErrorText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                weightErrorText!,
                                style: AppTypography.body5.copyWith(
                                  color: AppColors.error,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Color and markings
                        _buildTextArea(
                          label: 'Color y marcas distintivas (Opcional)',
                          hint: 'Haz una breve descripción',
                          controller: colorDescController,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Has identification?
                        Text(
                          '¿Tiene identificación? (Chip, arete, otros)',
                          style: AppTypography.body6,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            CustomRadioButton<String>(
                              value: 'si',
                              groupValue: hasIdentification,
                              label: 'Si',
                              onChanged: onHasIdentificationChanged,
                            ),
                            const SizedBox(width: AppSpacing.xxxl),
                            CustomRadioButton<String>(
                              value: 'no',
                              groupValue: hasIdentification,
                              label: 'No',
                              onChanged: onHasIdentificationChanged,
                            ),
                          ],
                        ),
                        if (hasIdentification == 'si') ...[
                          const SizedBox(height: AppSpacing.m),
                          AppDropdown<String>(
                            label: 'Tipo de identificación',
                            hint: 'Buscar o escribir',
                            value: selectedIdentificationType,
                            searchable: true,
                            isInline: true,
                            items: identificationTypeOptions
                                .map((t) => t.name)
                                .toList(),
                            itemAsString: (name) => name,
                            onChanged: onIdentificationTypeChanged,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          CustomTextField(
                            label: 'Número de identificación',
                            controller: identificationNumberController,
                            maxLength: 15,
                            strictValidation: true,
                            allowPattern: RegExp(r'^[a-zA-Z0-9]+$'),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.m),

                        // Belongs to association?
                        Text(
                          '¿Pertenece a alguna asociación?',
                          style: AppTypography.body6,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            CustomRadioButton<String>(
                              value: 'si',
                              groupValue: belongsToAssociation,
                              label: 'Si',
                              onChanged: onBelongsToAssociationChanged,
                            ),
                            const SizedBox(width: AppSpacing.xxxl),
                            CustomRadioButton<String>(
                              value: 'no',
                              groupValue: belongsToAssociation,
                              label: 'No',
                              onChanged: onBelongsToAssociationChanged,
                            ),
                          ],
                        ),
                        if (belongsToAssociation == 'si') ...[
                          const SizedBox(height: AppSpacing.m),
                          AppDropdown<String>(
                            label: 'Asociaciones',
                            hint: 'Buscar o escribir',
                            value: selectedAssociation,
                            searchable: true,
                            isInline: true,
                            items: associationOptions
                                .map((a) => a.name)
                                .toList(),
                            itemAsString: (name) => name,
                            onChanged: onAssociationChanged,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.m),

                        // Is Adopted?
                        Text(
                          '¿Es adoptado?',
                          style: AppTypography.body6,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            CustomRadioButton<bool>(
                              value: true,
                              groupValue: isAdopted,
                              label: 'Si',
                              onChanged: onIsAdoptedChanged,
                            ),
                            const SizedBox(width: AppSpacing.xxxl),
                            CustomRadioButton<bool>(
                              value: false,
                              groupValue: isAdopted,
                              label: 'No',
                              onChanged: onIsAdoptedChanged,
                            ),
                          ],
                        ),
                        if (isAdopted == true) ...[
                          const SizedBox(height: AppSpacing.m),
                          AppDropdown<String>(
                            label: '¿Dónde fue adoptado?',
                            hint: 'Buscar o escribir',
                            value: selectedAdoptionSource,
                            searchable: true,
                            isInline: true,
                            items: adoptionSourceOptions
                                .map((a) => a.name)
                                .toList(),
                            itemAsString: (name) => name,
                            onChanged: onAdoptionSourceChanged,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          CustomTextField(
                            label: 'Nombre del lugar (Opcional)',
                            controller: adoptionPlaceNameController,
                            maxLength: 50,
                            textCapitalization: TextCapitalization.sentences,
                            strictValidation: true,
                            allowPattern: RegExp(r'^[a-zA-Z0-9\s]+$'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (MediaQuery.of(context).viewInsets.bottom > 0)
                          SizedBox(
                            height:
                                (MediaQuery.of(context).viewInsets.bottom - 143)
                                    .clamp(0, double.infinity),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Fixed bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: SizedBox(
              width: 128,
              height: 39,
              child: CustomButton(
                text: 'Continuar',
                onPressed: isValid ? onContinue : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoArea(BuildContext context) {
    final hasLocalPhoto = selectedPhotoPath != null;

    return Center(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Foto del animal ', style: AppTypography.body6),
                TextSpan(
                  text: '(Opcional)',
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Photo container
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.bgHielo,
                  borderRadius: AppBorders.medium(),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLocalPhoto
                    ? Image.file(
                        File(selectedPhotoPath!),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : Center(
                        child: SvgPicture.asset(
                          _FamilySelectionStep._iconForSpecies(
                            selectedSpecies.name,
                          ),
                          width: AppSpacing.iconSizeMedium,
                          height: 35,
                        ),
                      ),
              ),
              // Edit button
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: GestureDetector(
                  onTap: () => _showImageSourceSheet(context),
                  child: Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: AppBorders.small(),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: AppSpacing.m,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    final picker = ImagePicker();
    final hasPhoto = selectedPhotoPath != null;

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
                    if (picked != null) onPhotoSelected(picked.path);
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
                    if (picked != null) onPhotoSelected(picked.path);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Eliminar foto',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onPhotoRemoved();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onChanged(!value);
      },
      child: Row(
        children: [
          // Custom toggle switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: AppSpacing.iconSizeSmall,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: value
                  ? AppColors.primaryFrances
                  : AppColors.greyDelineante,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label
                        .replaceAll(' (Opcional)', '')
                        .replaceAll('(Opcional)', '')
                        .trim(),
                    style: AppTypography.body6,
                  ),
                  if (label.contains('(Opcional)'))
                    TextSpan(
                      text: ' (Opcional)',
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyBordes,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.inputTopPadding),
        TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 150,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ0-9\s.,´]')),
          ],
          style: AppTypography.body4.copyWith(color: AppColors.greyNegroV2),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            hintText: hint,
            hintStyle: AppTypography.body4.copyWith(
              color: AppColors.greyBordes,
            ),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorders.small(),
              borderSide: const BorderSide(
                color: AppColors.greyBordes,
                width: 1.0,
              ),
            ),
            counterStyle: AppTypography.body6.copyWith(
              color: AppColors.greyBordes,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STEP 3 — Additional Info
// =============================================================================

class _AdditionalInfoStep extends StatelessWidget {
  final List<String> selectedTemperaments;
  final ValueChanged<List<String>> onTemperamentsChanged;
  final TextEditingController allergyController;
  final Map<String, bool> diagnoses;
  final void Function(String key, bool value) onDiagnosisChanged;
  final TextEditingController otherDiagnosisController;
  final bool isValid;
  final bool isLoading;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndAddAnother;

  // Dynamic catalog data from API
  final List<CatalogItemEntity> temperamentOptions;

  const _AdditionalInfoStep({
    required this.selectedTemperaments,
    required this.onTemperamentsChanged,
    required this.allergyController,
    required this.diagnoses,
    required this.onDiagnosisChanged,
    required this.otherDiagnosisController,
    required this.isValid,
    required this.isLoading,
    required this.onSave,
    required this.onSaveAndAddAnother,
    this.temperamentOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppColors.greyDelineante,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned.fill(
                child: RawScrollbar(
                  thumbColor: AppColors.primaryIndigo,
                  trackColor: Colors.transparent,
                  trackBorderColor: Colors.transparent,
                  radius: const Radius.circular(AppBorders.radiusSmall),
                  thickness: 2,
                  trackVisibility: false,
                  thumbVisibility: true,
                  interactive: false,
                  crossAxisMargin: 16,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temperament
                        AppMultiSearchDropdown<String>(
                          label: 'Temperamento',
                          hint: 'Seleccionar',
                          selectedItems: selectedTemperaments,
                          isInline: true,
                          searchable: false,
                          items: temperamentOptions.map((t) => t.name).toList(),
                          itemAsString: (item) => item,
                          onChanged: onTemperamentsChanged,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Allergy
                        CustomTextField(
                          label: 'Alergia a (Opcional)',
                          controller: allergyController,
                          maxLength: 80,
                          strictValidation: true,
                          allowPattern: RegExp(r'^[a-zA-Z0-9\s]+$'),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Diagnoses checkboxes
                        Text(
                          'Diagnosticado con',
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyNegroV2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        ...diagnoses.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCheckbox(
                              value: entry.value,
                              label: entry.key,
                              onChanged: (v) =>
                                  onDiagnosisChanged(entry.key, v),
                            ),
                          ),
                        ),

                        // "¿Cuál?" field (visible when "Otro" is checked)
                        if (diagnoses['Otro'] == true) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          CustomTextField(
                            label: '¿Cuál?',
                            controller: otherDiagnosisController,
                            maxLength: 80,
                            strictValidation: true,
                            allowPattern: RegExp(r'^[a-zA-Z0-9\s]+$'),
                          ),
                          const SizedBox(height: AppSpacing.m),
                        ],

                        if (diagnoses['Otro'] != true)
                          const SizedBox(height: AppSpacing.m),

                        const SizedBox(height: 8),
                        if (MediaQuery.of(context).viewInsets.bottom > 0)
                          SizedBox(
                            height:
                                (MediaQuery.of(context).viewInsets.bottom - 171)
                                    .clamp(0, double.infinity),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Fixed bottom: Save buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              SizedBox(
                width: 128,
                height: 39,
                child: CustomButton(
                  text: 'Guardar',
                  isLoading: isLoading,
                  onPressed: isValid && !isLoading ? onSave : null,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              GestureDetector(
                onTap: isValid && !isLoading ? onSaveAndAddAnother : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    'Guardar y agregar otro animal',
                    style: AppTypography.body3.copyWith(
                      color: isValid && !isLoading
                          ? AppColors.primaryFrances
                          : AppColors.primaryFrances.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ],
    );
  }
}
