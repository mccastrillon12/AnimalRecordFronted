import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/buttons/custom_radio_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';

void showAnimalFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlayBlack,
    constraints: const BoxConstraints(maxHeight: 621),
    builder: (context) => const AnimalFilterModal(),
  );
}

class AnimalFilterModal extends StatefulWidget {
  final String initialSex;
  final List<String> initialFamilies;
  final List<String> initialAges;

  const AnimalFilterModal({
    super.key,
    this.initialSex = 'Ambos',
    this.initialFamilies = const [],
    this.initialAges = const [],
  });

  @override
  State<AnimalFilterModal> createState() => _AnimalFilterModalState();
}

class _AnimalFilterModalState extends State<AnimalFilterModal> {
  late String _selectedSex;
  late Set<String> _selectedFamilies;
  late List<String> _selectedAges;

  @override
  void initState() {
    super.initState();
    _selectedSex = widget.initialSex;
    _selectedFamilies = widget.initialFamilies.toSet();
    _selectedAges = List.from(widget.initialAges);
  }

  final List<String> _ageOptions = [
    '0-6 meses',
    '7-11 meses',
    '1-3 años',
    '4-6 años',
    '7-10 años',
    '11-15 años',
    '16-20 años',
    '21-25 años',
    '+25 años',
  ];

  bool get _hasFilters {
    return _selectedSex != 'Ambos' ||
        _selectedFamilies.isNotEmpty ||
        _selectedAges.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _selectedSex = 'Ambos';
      _selectedFamilies.clear();
      _selectedAges = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 630,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, {
                          'sex': _selectedSex,
                          'families': _selectedFamilies.toList(),
                          'ages': _selectedAges,
                        }),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.greyNegro,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/vuesax-bold-setting-4.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColors.primaryIndigo,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtros',
                          style: AppTypography.heading1.copyWith(
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sex
                        Text('Sexo', style: AppTypography.body6),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomRadioButton<String>(
                              value: 'Ambos',
                              groupValue: _selectedSex,
                              label: 'Ambos',
                              onChanged: (v) =>
                                  setState(() => _selectedSex = v!),
                            ),
                            CustomRadioButton<String>(
                              value: 'Macho',
                              groupValue: _selectedSex,
                              label: 'Macho',
                              onChanged: (v) =>
                                  setState(() => _selectedSex = v!),
                            ),
                            CustomRadioButton<String>(
                              value: 'Hembra',
                              groupValue: _selectedSex,
                              label: 'Hembra',
                              onChanged: (v) =>
                                  setState(() => _selectedSex = v!),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(
                          color: AppColors.greyDelineante,
                          height: 1,
                        ),
                        const SizedBox(height: 24),

                        // Familia
                        Text('Familia', style: AppTypography.body6),
                        const SizedBox(height: AppSpacing.l),
                        Center(
                          child: SizedBox(
                            width:
                                170, // 72 (card) + 20 (spacing) + 72 (card) = 164 -> 170 ensures exactly 2 per row
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildFamilyCard(
                                  'Felino',
                                  'assets/illustrations/cat_icon.svg',
                                ),
                                _buildFamilyCard(
                                  'Canino',
                                  'assets/illustrations/dog_icon.svg',
                                ),
                                _buildFamilyCard(
                                  'Bovino',
                                  'assets/illustrations/bovino_icon.svg',
                                ),
                                _buildFamilyCard(
                                  'Equino',
                                  'assets/illustrations/equino_icon.svg',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(
                          color: AppColors.greyDelineante,
                          height: 1,
                        ),
                        const SizedBox(height: 24),

                        // Edad
                        AppMultiSearchDropdown<String>(
                          label: 'Edad',
                          hint: 'Selecciona rango de edad',
                          selectedItems: _selectedAges,
                          items: _ageOptions,
                          itemAsString: (item) => item,
                          isInline: true,
                          searchable: false,
                          onChanged: (v) => setState(() => _selectedAges = v),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _hasFilters ? _clearFilters : null,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Limpiar filtros',
                          style: AppTypography.body4.copyWith(
                            color: _hasFilters
                                ? AppColors.primaryFrances
                                : AppColors.primaryFrances.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context, {
                          'sex': _selectedSex,
                          'families': _selectedFamilies.toList(),
                          'ages': _selectedAges,
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Filtrar',
                          style: AppTypography.body4.copyWith(
                            color: _hasFilters
                                ? AppColors.primaryFrances
                                : AppColors.primaryFrances.withValues(
                                    alpha: 0.4,
                                  ),
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
      ),
    );
  }

  Widget _buildFamilyCard(String name, String iconAsset) {
    final isSelected = _selectedFamilies.contains(name);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFamilies.remove(name);
          } else {
            _selectedFamilies.add(name);
          }
        });
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bgHielo : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryFrances : AppColors.greyBordes,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryFrances.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: AppSpacing.iconSizeMedium,
              height: 35,
              colorFilter: isSelected
                  ? const ColorFilter.mode(
                      AppColors.primaryFrances,
                      BlendMode.srcIn,
                    )
                  : null,
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: AppTypography.body5.copyWith(
                color: isSelected
                    ? AppColors.primaryFrances
                    : AppColors.greyTextos,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
