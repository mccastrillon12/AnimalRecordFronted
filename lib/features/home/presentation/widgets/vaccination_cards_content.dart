import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_vaccinations_screen.dart';
import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_filter_modal.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_list_control_button.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VaccinationCardsContent extends StatefulWidget {
  final AnimalMedicalDocumentsCubit Function()? createDocumentsCubit;

  const VaccinationCardsContent({super.key, this.createDocumentsCubit});

  @override
  State<VaccinationCardsContent> createState() =>
      _VaccinationCardsContentState();
}

class _VaccinationCardsContentState extends State<VaccinationCardsContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _collapsedFamilies = {};
  String _searchQuery = '';
  String _filterSex = 'Ambos';
  List<String> _filterFamilies = [];
  List<String> _filterAges = [];

  bool get _hasActiveFilters =>
      _filterSex != 'Ambos' ||
      _filterFamilies.isNotEmpty ||
      _filterAges.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalCubit, AnimalState>(
      builder: (context, state) {
        if (state is AnimalsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryFrances),
          );
        }

        final animals = _animalsFromState(
          state,
        ).where(_matchesSearch).where(_matchesFilters).toList(growable: false);
        final grouped = _groupAnimals(animals);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(
                'Carné vacunas',
                key: const Key('vaccination-cards-title'),
                style: AppTypography.heading2,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Row(
                children: [
                  Expanded(
                    child: AnimalRecordSearchField(
                      controller: _searchController,
                      fieldKey: const Key('vaccination-cards-search-field'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.l),
                  AnimalListControlButton(
                    buttonKey: const Key('vaccination-cards-filter-button'),
                    onTap: _openFilters,
                    child: SvgPicture.asset(
                      'assets/icons/vuesax-bold-setting-4.svg',
                      width: AppSpacing.iconSizeSmall,
                      height: AppSpacing.iconSizeSmall,
                      colorFilter: ColorFilter.mode(
                        _hasActiveFilters
                            ? AppColors.primaryFrances
                            : AppColors.greyMedio,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron animales',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyTextos,
                        ),
                      ),
                    )
                  : ListView(
                      key: const Key('vaccination-cards-groups'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.l,
                        0,
                        AppSpacing.l,
                        AppSpacing.xl,
                      ),
                      children: [
                        for (final entry in grouped.entries)
                          _familySection(entry.key, entry.value),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _familySection(String family, List<AnimalModel> animals) {
    final collapsed = _collapsedFamilies.contains(family);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: Key('vaccination-family-$family'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            collapsed
                ? _collapsedFamilies.remove(family)
                : _collapsedFamilies.add(family);
          }),
          child: Container(
            height: AppSpacing.xxxl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyDelineante, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(family, style: AppTypography.heading2),
                RotatedBox(
                  quarterTurns: collapsed ? 0 : 1,
                  child: SvgPicture.asset(
                    'assets/icons/arrow-right.svg',
                    width: AppSpacing.iconSizeSmall,
                    height: AppSpacing.iconSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!collapsed)
          for (final animal in animals)
            _AnimalVaccinationSummary(
              key: ValueKey('vaccination-summary-${animal.id}'),
              animal: animal,
              createDocumentsCubit:
                  widget.createDocumentsCubit ??
                  () => di.sl<AnimalMedicalDocumentsCubit>(),
            ),
        const SizedBox(height: AppSpacing.l),
      ],
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlayBlack,
      builder: (_) => AnimalFilterModal(
        initialSex: _filterSex,
        initialFamilies: _filterFamilies,
        initialAges: _filterAges,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _filterSex = result['sex'] as String? ?? 'Ambos';
      _filterFamilies = result['families'] as List<String>? ?? [];
      _filterAges = result['ages'] as List<String>? ?? [];
    });
  }

  bool _matchesSearch(AnimalModel animal) {
    final query = _searchQuery.trim().toLowerCase();
    return query.isEmpty ||
        animal.name.toLowerCase().contains(query) ||
        animal.code.toLowerCase().contains(query) ||
        (animal.breed?.toLowerCase().contains(query) ?? false);
  }

  bool _matchesFilters(AnimalModel animal) {
    if (_filterSex != 'Ambos' && animal.sexDisplay != _filterSex) return false;
    if (_filterFamilies.isNotEmpty &&
        !_filterFamilies.contains(animalFamilyLabel(animal.family))) {
      return false;
    }
    if (_filterAges.isEmpty) return true;
    final ageMonths = _ageInMonths(animal);
    return ageMonths != null &&
        _filterAges.any((range) => _ageRange(range).contains(ageMonths));
  }

  int? _ageInMonths(AnimalModel animal) {
    if (animal.approximateAgeMinMonths != null &&
        animal.approximateAgeMaxMonths != null) {
      return ((animal.approximateAgeMinMonths! +
                  animal.approximateAgeMaxMonths!) /
              2)
          .round();
    }
    final birthdate = DateTime.tryParse(animal.birthdate ?? '');
    if (birthdate == null) return null;
    final now = DateTime.now();
    return (now.year - birthdate.year) * 12 + now.month - birthdate.month;
  }

  ({int min, int max}) _ageRange(String label) => switch (label) {
    '0-6 meses' => (min: 0, max: 6),
    '7-11 meses' => (min: 7, max: 11),
    '1-3 años' => (min: 12, max: 36),
    '4-6 años' => (min: 48, max: 72),
    '7-10 años' => (min: 84, max: 120),
    '11-15 años' => (min: 132, max: 180),
    '16-20 años' => (min: 192, max: 240),
    '21-25 años' => (min: 252, max: 300),
    '+25 años' => (min: 301, max: 1200),
    _ => (min: 0, max: 1200),
  };

  Map<String, List<AnimalModel>> _groupAnimals(List<AnimalModel> animals) {
    final grouped = <String, List<AnimalModel>>{};
    final inactive = <AnimalModel>[];
    for (final animal in animals) {
      if (!animal.isActive) {
        inactive.add(animal);
        continue;
      }
      final family = pluralizeAnimalFamily(animal.family);
      grouped.putIfAbsent(family, () => []).add(animal);
    }
    if (inactive.isNotEmpty) grouped['Transferidos e inactivos'] = inactive;
    return grouped;
  }

  List<AnimalModel> _animalsFromState(AnimalState state) {
    final List<AnimalEntity> entities = switch (state) {
      AnimalsLoaded(:final animals) => animals,
      AnimalCreated(:final allAnimals) => allAnimals,
      AnimalCreating(:final existingAnimals) => existingAnimals,
      AnimalUpdated(:final allAnimals) => allAnimals,
      AnimalUpdating(:final existingAnimals) => existingAnimals,
      AnimalPictureUploaded(:final allAnimals) => allAnimals,
      AnimalPictureUploading(:final existingAnimals) => existingAnimals,
      AnimalError(:final existingAnimals) => existingAnimals,
      _ => const [],
    };
    return entities.map(AnimalModel.fromEntity).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }
}

extension on ({int min, int max}) {
  bool contains(int value) => value >= min && value <= max;
}

class _AnimalVaccinationSummary extends StatelessWidget {
  final AnimalModel animal;
  final AnimalMedicalDocumentsCubit Function() createDocumentsCubit;

  const _AnimalVaccinationSummary({
    super.key,
    required this.animal,
    required this.createDocumentsCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnimalMedicalDocumentsCubit>(
      create: (_) => createDocumentsCubit()
        ..load(animal.id, category: MedicalDocumentCategory.vaccinationCard),
      child: _AnimalVaccinationSummaryContent(animal: animal),
    );
  }
}

class _AnimalVaccinationSummaryContent extends StatelessWidget {
  final AnimalModel animal;

  const _AnimalVaccinationSummaryContent({required this.animal});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AnimalMedicalDocumentsCubit,
      AnimalMedicalDocumentsState
    >(
      builder: (context, state) {
        final summary = _summary(state);
        return InkWell(
          key: Key('vaccination-animal-${animal.id}'),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AnimalMedicalDocumentsCubit>(),
                child: AnimalVaccinationsScreen(animal: animal),
              ),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 81),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.m,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyDelineante),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimalAvatar(animal: animal, size: 40, borderRadius: 6),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              animal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body3.copyWith(
                                color: AppColors.greyTextos,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            animal.code,
                            style: AppTypography.body5.copyWith(
                              color: AppColors.greyBordes,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _SummaryValue(
                        label: 'Próx. dosis',
                        value: summary.vaccine,
                      ),
                      _SummaryValue(label: 'Fecha', value: summary.date),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ({String vaccine, String date}) _summary(AnimalMedicalDocumentsState state) {
    if (state is AnimalMedicalDocumentsLoading) {
      return (vaccine: 'Cargando...', date: '-');
    }
    if (state is! AnimalMedicalDocumentsLoaded) {
      return (vaccine: 'No tiene dosis pendiente', date: '-');
    }
    final groups = sortVaccinationGroupsByLatest(
      groupVaccinations(state.documents),
    );
    for (final group in groups) {
      if (group.latest.nextDoseDate.isNotEmpty) {
        return (vaccine: group.title, date: group.latest.nextDoseDate);
      }
    }
    return (vaccine: 'No tiene dosis pendiente', date: '-');
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 114,
          child: Text(
            label,
            style: AppTypography.body5.copyWith(color: AppColors.greyBordes),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
        ),
      ],
    );
  }
}
