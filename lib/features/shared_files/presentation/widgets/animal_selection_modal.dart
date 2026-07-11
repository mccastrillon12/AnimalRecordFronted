import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/buttons/custom_checkbox.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/layout/base_modal_card.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<List<AnimalEntity>?> showAnimalSelectionModal({
  required BuildContext context,
  required List<AnimalEntity> animals,
  required List<AnimalEntity> selectedAnimals,
}) {
  return showDialog<List<AnimalEntity>>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.overlayBlack,
    builder: (_) => AnimalSelectionModal(
      animals: animals,
      selectedAnimals: selectedAnimals,
    ),
  );
}

class AnimalSelectionModal extends StatefulWidget {
  final List<AnimalEntity> animals;
  final List<AnimalEntity> selectedAnimals;

  const AnimalSelectionModal({
    super.key,
    required this.animals,
    required this.selectedAnimals,
  });

  @override
  State<AnimalSelectionModal> createState() => _AnimalSelectionModalState();
}

class _AnimalSelectionModalState extends State<AnimalSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedAnimals.map((animal) => animal.id).toSet();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  List<AnimalEntity> get _filteredAnimals {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.animals;
    return widget.animals
        .where((animal) {
          return animal.name.toLowerCase().contains(query) ||
              (animal.code?.toLowerCase().contains(query) ?? false) ||
              animal.species.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Map<String, List<AnimalEntity>> get _groupedAnimals {
    final groups = <String, List<AnimalEntity>>{};
    for (final animal in _filteredAnimals) {
      groups
          .putIfAbsent(pluralizeAnimalFamily(animal.species), () => [])
          .add(animal);
    }
    return groups;
  }

  bool get _allSelected =>
      widget.animals.isNotEmpty &&
      widget.animals.every((animal) => _selectedIds.contains(animal.id));

  void _toggleAnimal(AnimalEntity animal, bool selected) {
    setState(() {
      selected ? _selectedIds.add(animal.id) : _selectedIds.remove(animal.id);
    });
  }

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(widget.animals.map((animal) => animal.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _continue() {
    final selected = widget.animals
        .where((animal) => _selectedIds.contains(animal.id))
        .toList(growable: false);
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalCard(
      title: 'Seleccionar animales',
      subtitle: Text(
        '${_selectedIds.length} seleccionados',
        style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
      ),
      onClose: () => Navigator.of(context).pop(),
      bottomChild: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.l),
        child: SizedBox(
          width: 118,
          child: CustomButton(
            text: 'Continuar',
            onPressed: _selectedIds.isEmpty ? null : _continue,
          ),
        ),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.52,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                children: [
                  CustomTextField(
                    label: '',
                    hint: 'Buscar',
                    controller: _searchController,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: AppSpacing.xs,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/vuesax-linear-search-2.svg',
                        width: AppSpacing.iconSizeSmall,
                        height: AppSpacing.iconSizeSmall,
                        colorFilter: const ColorFilter.mode(
                          AppColors.greyMedio,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  CustomCheckbox(
                    value: _allSelected,
                    label: 'Seleccionar todos',
                    onChanged: _toggleAll,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
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
                      radius: const Radius.circular(4),
                      thickness: 2,
                      trackVisibility: false,
                      thumbVisibility: true,
                      interactive: false,
                      crossAxisMargin: 16,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 22, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildGroups(),
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
  }

  List<Widget> _buildGroups() {
    if (_groupedAnimals.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            'No se encontraron animales',
            textAlign: TextAlign.center,
            style: AppTypography.body4.copyWith(color: AppColors.greyMedio),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final entry in _groupedAnimals.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Text(entry.key, style: AppTypography.body3),
        ),
      );
      for (final animal in entry.value) {
        final code = animal.code?.trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: CustomCheckbox(
              value: _selectedIds.contains(animal.id),
              label: animal.name,
              labelWidget: RichText(
                text: TextSpan(
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                  children: [
                    TextSpan(text: animal.name),
                    if (code?.isNotEmpty == true)
                      TextSpan(
                        text: ' - $code',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyBordes,
                        ),
                      ),
                  ],
                ),
              ),
              onChanged: (selected) => _toggleAnimal(animal, selected),
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 2));
    }
    return widgets;
  }
}
