import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:animal_record/core/widgets/dropdowns/custom_dropdown_field.dart';
import 'package:animal_record/features/home/domain/models/animal_family.dart';
import 'package:animal_record/features/home/domain/entities/create_animal_params.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';

/// Opens the AnimalCreationModal as an overlay dialog on the current screen.
void showAnimalCreationModal(BuildContext context) {
  final animalCubit = context.read<AnimalCubit>();
  showBaseModalCard(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: animalCubit,
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
  AnimalFamily? _selectedFamily;

  // — Step 2 state —
  final _nameController = TextEditingController();
  String? _selectedBreed;
  String? _selectedSex;
  String? _reproductiveState;
  DateTime? _birthDate;
  bool _unknownExactDate = false;
  final _weightKgController = TextEditingController();
  final _weightLbController = TextEditingController();
  final _colorDescController = TextEditingController();
  String? _hasIdentification;
  String? _belongsToAssociation;

  // — Step 3 state —
  String? _selectedTemperament;
  final _allergyController = TextEditingController();
  final Map<String, bool> _diagnoses = {
    'Ninguno/Desconocido': false,
    'Mielopatía degenerativa': false,
    'Displasia de cadera': false,
    'Leishmaniasis': false,
    'Otro': false,
  };
  final _otherDiagnosisController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _weightKgController.dispose();
    _weightLbController.dispose();
    _colorDescController.dispose();
    _allergyController.dispose();
    _otherDiagnosisController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _goNext() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  void _onFamilySelected(AnimalFamily family) {
    setState(() {
      _selectedFamily = family;
      _currentStep = 2;
    });
  }

  // =========================================================================
  // Validation
  // =========================================================================

  bool get _isStep2Valid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedBreed != null &&
        _selectedSex != null &&
        _reproductiveState != null &&
        (_birthDate != null || _unknownExactDate) &&
        _hasIdentification != null &&
        _belongsToAssociation != null;
  }

  bool get _isStep3Valid {
    return _selectedTemperament != null &&
        _diagnoses.values.any((v) => v);
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
      species: _selectedFamily!.apiSpecies, // "BOVINE", "CAT", "DOG", "HORSE"
      breed: _selectedBreed!, // ej: "mestizo", "labrador"
      sex: _selectedSex!, // ej: "macho", "hembra"
      reproductiveStatus: _reproductiveState!, // ej: "esterilizado"
      birthdate: _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      hasChip: _hasIdentification == 'Sí',
      isAssociationMember: _belongsToAssociation == 'Sí',
      temperament: [_selectedTemperament!], // ej: "independiente"
      diagnosis: selectedDiagnoses.isEmpty ? ['Ninguno'] : selectedDiagnoses,
      ownerId: ownerId,
      weight: double.tryParse(_weightKgController.text.trim()),
      colorAndMarkings: _colorDescController.text.trim().isNotEmpty
          ? _colorDescController.text.trim()
          : null,
      allergies: _allergyController.text.trim().isNotEmpty
          ? _allergyController.text.trim()
          : null,
    );
  }

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
      _selectedFamily = null;
      _nameController.clear();
      _selectedBreed = null;
      _selectedSex = null;
      _reproductiveState = null;
      _birthDate = null;
      _unknownExactDate = false;
      _weightKgController.clear();
      _weightLbController.clear();
      _colorDescController.clear();
      _hasIdentification = null;
      _belongsToAssociation = null;
      _selectedTemperament = null;
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
            style: AppTypography.body3.copyWith(
              color: AppColors.greyTextos,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: ' - $_currentStep de $_totalSteps',
            style: AppTypography.body3.copyWith(
              color: AppColors.greyBordes,
              fontWeight: FontWeight.w400,
            ),
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
          if (_pendingAddAnother) {
            _pendingAddAnother = false;
            context.read<AnimalCubit>().resetToLoaded();
            _resetForm();
          } else {
            context.read<AnimalCubit>().resetToLoaded();
            Navigator.pop(context);
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
        onClose: () => Navigator.pop(context),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _FamilySelectionStep(
          onFamilySelected: _onFamilySelected,
        );
      case 2:
        return _AnimalInfoStep(
          selectedFamily: _selectedFamily!,
          nameController: _nameController,
          selectedBreed: _selectedBreed,
          onBreedChanged: (v) => setState(() => _selectedBreed = v),
          selectedSex: _selectedSex,
          onSexChanged: (v) => setState(() => _selectedSex = v),
          reproductiveState: _reproductiveState,
          onReproductiveStateChanged: (v) =>
              setState(() => _reproductiveState = v),
          birthDate: _birthDate,
          onBirthDateChanged: (v) => setState(() => _birthDate = v),
          unknownExactDate: _unknownExactDate,
          onUnknownExactDateChanged: (v) =>
              setState(() => _unknownExactDate = v),
          weightKgController: _weightKgController,
          weightLbController: _weightLbController,
          colorDescController: _colorDescController,
          hasIdentification: _hasIdentification,
          onHasIdentificationChanged: (v) =>
              setState(() => _hasIdentification = v),
          belongsToAssociation: _belongsToAssociation,
          onBelongsToAssociationChanged: (v) =>
              setState(() => _belongsToAssociation = v),
          isValid: _isStep2Valid,
          onContinue: _isStep2Valid ? _goNext : null,
        );
      case 3:
        return BlocBuilder<AnimalCubit, AnimalState>(
          builder: (context, state) {
            final isLoading = state is AnimalCreating;
            return _AdditionalInfoStep(
              selectedTemperament: _selectedTemperament,
              onTemperamentChanged: (v) =>
                  setState(() => _selectedTemperament = v),
              allergyController: _allergyController,
              diagnoses: _diagnoses,
              onDiagnosisChanged: (key, value) =>
                  setState(() => _diagnoses[key] = value),
              otherDiagnosisController: _otherDiagnosisController,
              isValid: _isStep3Valid,
              isLoading: isLoading,
              onSave: _isStep3Valid && !isLoading
                  ? () => _saveAnimal()
                  : null,
              onSaveAndAddAnother: _isStep3Valid && !isLoading
                  ? () => _saveAnimal(addAnother: true)
                  : null,
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
  final ValueChanged<AnimalFamily> onFamilySelected;

  const _FamilySelectionStep({required this.onFamilySelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            'Elige a qué familia pertenece tu animal',
            style: AppTypography.body4.copyWith(
              color: AppColors.greyTextos,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _FamilyCard(
                  family: AnimalFamily.felino,
                  onTap: () => onFamilySelected(AnimalFamily.felino),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FamilyCard(
                  family: AnimalFamily.canino,
                  onTap: () => onFamilySelected(AnimalFamily.canino),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FamilyCard(
                  family: AnimalFamily.bovino,
                  onTap: () => onFamilySelected(AnimalFamily.bovino),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FamilyCard(
                  family: AnimalFamily.equino,
                  onTap: () => onFamilySelected(AnimalFamily.equino),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final AnimalFamily family;
  final VoidCallback onTap;

  const _FamilyCard({required this.family, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.medium(),
          border: Border.all(
            color: AppColors.greyDelineante,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              family.iconAsset,
              width: 48,
              height: 48,
            ),
            const SizedBox(height: 4),
            Text(
              family.displayName,
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
              ),
            ),
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
  final AnimalFamily selectedFamily;
  final TextEditingController nameController;
  final String? selectedBreed;
  final ValueChanged<String?> onBreedChanged;
  final String? selectedSex;
  final ValueChanged<String?> onSexChanged;
  final String? reproductiveState;
  final ValueChanged<String?> onReproductiveStateChanged;
  final DateTime? birthDate;
  final ValueChanged<DateTime> onBirthDateChanged;
  final bool unknownExactDate;
  final ValueChanged<bool> onUnknownExactDateChanged;
  final TextEditingController weightKgController;
  final TextEditingController weightLbController;
  final TextEditingController colorDescController;
  final String? hasIdentification;
  final ValueChanged<String?> onHasIdentificationChanged;
  final String? belongsToAssociation;
  final ValueChanged<String?> onBelongsToAssociationChanged;
  final bool isValid;
  final VoidCallback? onContinue;

  const _AnimalInfoStep({
    required this.selectedFamily,
    required this.nameController,
    required this.selectedBreed,
    required this.onBreedChanged,
    required this.selectedSex,
    required this.onSexChanged,
    required this.reproductiveState,
    required this.onReproductiveStateChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.unknownExactDate,
    required this.onUnknownExactDateChanged,
    required this.weightKgController,
    required this.weightLbController,
    required this.colorDescController,
    required this.hasIdentification,
    required this.onHasIdentificationChanged,
    required this.belongsToAssociation,
    required this.onBelongsToAssociationChanged,
    required this.isValid,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: RawScrollbar(
            thumbColor: AppColors.primaryIndigo,
            trackColor: AppColors.greyDelineante,
            radius: const Radius.circular(AppBorders.radiusSmall),
            thickness: 2,
            trackVisibility: true,
            thumbVisibility: true,
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
                          style: AppTypography.body3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.greyNegro,
                          ),
                        ),
                        TextSpan(
                          text: selectedFamily.displayName,
                          style: AppTypography.body3.copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColors.greyNegro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo area
                  _buildPhotoArea(),
                  const SizedBox(height: 24),

                  // Name
                  CustomTextField(
                    label: 'Nombre',
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),

                  // Breed dropdown
                  CustomDropdownField<String>(
                    label: 'Raza',
                    hint: 'Seleccionar raza',
                    value: selectedBreed,
                    items: const [
                      DropdownMenuItem(value: 'mestizo', child: Text('Mestizo')),
                      DropdownMenuItem(value: 'labrador', child: Text('Labrador')),
                      DropdownMenuItem(value: 'pastor_aleman', child: Text('Pastor Alemán')),
                      DropdownMenuItem(value: 'bulldog', child: Text('Bulldog')),
                      DropdownMenuItem(value: 'golden', child: Text('Golden Retriever')),
                      DropdownMenuItem(value: 'poodle', child: Text('Poodle')),
                    ],
                    onChanged: onBreedChanged,
                  ),
                  const SizedBox(height: 16),

                  // Sex
                  Text(
                    'Sexo',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'macho',
                          groupValue: selectedSex,
                          label: 'Macho',
                          onChanged: onSexChanged,
                        ),
                      ),
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'hembra',
                          groupValue: selectedSex,
                          label: 'Hembra',
                          onChanged: onSexChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reproductive state
                  Text(
                    'Estado reproductivo',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomRadioButton<String>(
                    value: 'esterilizado',
                    groupValue: reproductiveState,
                    label: 'Esterilizado',
                    onChanged: onReproductiveStateChanged,
                  ),
                  const SizedBox(height: 8),
                  CustomRadioButton<String>(
                    value: 'no_esterilizado',
                    groupValue: reproductiveState,
                    label: 'No esterilizado',
                    onChanged: onReproductiveStateChanged,
                  ),
                  const SizedBox(height: 8),
                  CustomRadioButton<String>(
                    value: 'desconocido',
                    groupValue: reproductiveState,
                    label: 'Desconocido',
                    onChanged: onReproductiveStateChanged,
                  ),
                  const SizedBox(height: 16),

                  // Birth date
                  CustomDateField(
                    label: 'Fecha de nacimiento',
                    value: birthDate,
                    onChanged: onBirthDateChanged,
                    enabled: !unknownExactDate,
                  ),
                  const SizedBox(height: 12),

                  // Unknown date toggle
                  _buildToggle(
                    label: 'No sé la fecha exacta',
                    value: unknownExactDate,
                    onChanged: onUnknownExactDateChanged,
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Peso ',
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyNegroV2,
                          ),
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
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: '',
                          hint: '- kg',
                          controller: weightKgController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: '',
                          hint: '- lb',
                          controller: weightLbController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Color and markings
                  _buildTextArea(
                    label: 'Color y marcas distintivas (Opcional)',
                    hint: 'Haz una breve descripción',
                    controller: colorDescController,
                  ),
                  const SizedBox(height: 16),

                  // Has identification?
                  Text(
                    '¿Tiene identificación? (Chip, arete, otros)',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'si',
                          groupValue: hasIdentification,
                          label: 'Si',
                          onChanged: onHasIdentificationChanged,
                        ),
                      ),
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'no',
                          groupValue: hasIdentification,
                          label: 'No',
                          onChanged: onHasIdentificationChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Belongs to association?
                  Text(
                    '¿Pertenece a alguna asociación?',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'si',
                          groupValue: belongsToAssociation,
                          label: 'Si',
                          onChanged: onBelongsToAssociationChanged,
                        ),
                      ),
                      Expanded(
                        child: CustomRadioButton<String>(
                          value: 'no',
                          groupValue: belongsToAssociation,
                          label: 'No',
                          onChanged: onBelongsToAssociationChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Fixed bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: CustomButton(
            text: 'Continuar',
            onPressed: isValid ? onContinue : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoArea() {
    return Center(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Foto del animal ',
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyNegroV2,
                  ),
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
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Photo container
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.bgHielo,
                  borderRadius: AppBorders.medium(),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    selectedFamily.iconAsset,
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              // Edit button
              Positioned(
                top: 0,
                right: -4,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement photo picker
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
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

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          // Custom toggle switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: value ? AppColors.primaryFrances : AppColors.greyDelineante,
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
              style: AppTypography.body4.copyWith(
                color: AppColors.textPrimary,
              ),
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
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
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
          maxLength: 200,
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
  final String? selectedTemperament;
  final ValueChanged<String?> onTemperamentChanged;
  final TextEditingController allergyController;
  final Map<String, bool> diagnoses;
  final void Function(String key, bool value) onDiagnosisChanged;
  final TextEditingController otherDiagnosisController;
  final bool isValid;
  final bool isLoading;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndAddAnother;

  const _AdditionalInfoStep({
    required this.selectedTemperament,
    required this.onTemperamentChanged,
    required this.allergyController,
    required this.diagnoses,
    required this.onDiagnosisChanged,
    required this.otherDiagnosisController,
    required this.isValid,
    required this.isLoading,
    required this.onSave,
    required this.onSaveAndAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RawScrollbar(
            thumbColor: AppColors.primaryIndigo,
            trackColor: AppColors.greyDelineante,
            radius: const Radius.circular(AppBorders.radiusSmall),
            thickness: 2,
            trackVisibility: true,
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Temperament
                  CustomDropdownField<String>(
                    label: 'Temperamento',
                    hint: 'Seleccionar',
                    value: selectedTemperament,
                    items: const [
                      DropdownMenuItem(
                        value: 'independiente',
                        child: Text('Independiente'),
                      ),
                      DropdownMenuItem(
                        value: 'docil',
                        child: Text('Dócil'),
                      ),
                      DropdownMenuItem(
                        value: 'agresivo',
                        child: Text('Agresivo'),
                      ),
                      DropdownMenuItem(
                        value: 'miedoso',
                        child: Text('Miedoso'),
                      ),
                      DropdownMenuItem(
                        value: 'jugueton',
                        child: Text('Juguetón'),
                      ),
                    ],
                    onChanged: onTemperamentChanged,
                  ),
                  const SizedBox(height: 16),

                  // Allergy
                  CustomTextField(
                    label: 'Alergia a (Opcional)',
                    controller: allergyController,
                  ),
                  const SizedBox(height: 16),

                  // Diagnoses checkboxes
                  Text(
                    'Diagnosticado con',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.greyNegroV2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...diagnoses.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCheckbox(
                      value: entry.value,
                      label: entry.key,
                      onChanged: (v) => onDiagnosisChanged(entry.key, v),
                    ),
                  )),

                  // "¿Cuál?" field (visible when "Otro" is checked)
                  if (diagnoses['Otro'] == true) ...[
                    const SizedBox(height: 4),
                    CustomTextField(
                      label: '¿Cuál?',
                      controller: otherDiagnosisController,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (diagnoses['Otro'] != true)
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Fixed bottom: Save buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              CustomButton(
                text: 'Guardar',
                isLoading: isLoading,
                onPressed: isValid && !isLoading ? onSave : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: isValid && !isLoading ? onSaveAndAddAnother : null,
                child: Text(
                  'Guardar y agregar otro animal',
                  style: AppTypography.body3.copyWith(
                    color: isValid && !isLoading
                        ? AppColors.primaryFrances
                        : AppColors.greyBordes,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
