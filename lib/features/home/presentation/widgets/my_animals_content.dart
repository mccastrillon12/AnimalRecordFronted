import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_creation_modal.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_filter_modal.dart';
import 'package:animal_record/core/constants/app_routes.dart';

/// Full "Mis Animales" page with search bar, grid/list toggle, filter, and
/// animals grouped by species (family).
class MyAnimalsContent extends StatefulWidget {
  const MyAnimalsContent({super.key});

  @override
  State<MyAnimalsContent> createState() => _MyAnimalsContentState();
}

class _MyAnimalsContentState extends State<MyAnimalsContent> {
  AnimalCardMode _viewMode = AnimalCardMode.grid;
  String _searchQuery = '';
  final Set<String> _collapsedFamilies = {};
  final TextEditingController _searchController = TextEditingController();

  String _currentFilterSex = 'Ambos';
  List<String> _currentFilterFamilies = [];
  List<String> _currentFilterAges = [];

  bool get _hasActiveFilters =>
      _currentFilterSex != 'Ambos' ||
      _currentFilterFamilies.isNotEmpty ||
      _currentFilterAges.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == AnimalCardMode.list
          ? AnimalCardMode.grid
          : AnimalCardMode.list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalCubit, AnimalState>(
      builder: (context, state) {
        final List<AnimalModel> allAnimals;
        if (state is AnimalsLoaded) {
          allAnimals = state.animals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalCreated) {
          allAnimals = state.allAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalCreating) {
          allAnimals = state.existingAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalError) {
          allAnimals = state.existingAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else {
          allAnimals = [];
        }

        if (state is AnimalsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by search
        final filtered = _searchQuery.isEmpty
            ? allAnimals
            : allAnimals
                  .where(
                    (a) =>
                        a.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        a.code.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        (a.breed?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();

        // Group by family
        final Map<String, List<AnimalModel>> grouped = {};
        for (final animal in filtered) {
          final pluralFamily = _pluralizeFamily(animal.family);
          grouped.putIfAbsent(pluralFamily, () => []);
          grouped[pluralFamily]!.add(animal);
        }

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Text(
                    'Mis animales',
                    style: AppTypography.heading2.copyWith(),
                  ),
                ),

                const SizedBox(height: AppSpacing.l),

                // Search bar + view toggle + filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.iconSizeMedium,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: AppTypography.body4,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              isDense: true,
                              hintText: 'Buscar',
                              hintStyle: AppTypography.body4.copyWith(
                                color: AppColors.greyBordes,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 8,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/vuesax-linear-search-2.svg',
                                  width: AppSpacing.iconSizeSmall,
                                  height: AppSpacing.iconSizeSmall,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF59667A),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA8AFBD),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFA8AFBD),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0072BB),
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.l),

                      // View toggle
                      _buildIconButton(
                        child: SvgPicture.asset(
                          _viewMode == AnimalCardMode.list
                              ? 'assets/icons/vuesax-bold-element-3.svg'
                              : 'assets/icons/vuesax-bold-fatrows.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColors.greyMedio,
                            BlendMode.srcIn,
                          ),
                          width: AppSpacing.iconSizeSmall,
                          height: AppSpacing.iconSizeSmall,
                        ),
                        onTap: _toggleViewMode,
                      ),

                      const SizedBox(width: AppSpacing.m),

                      // Filter button
                      _buildIconButton(
                        child: SvgPicture.asset(
                          'assets/icons/vuesax-bold-setting-4.svg',
                          colorFilter: ColorFilter.mode(
                            _hasActiveFilters
                                ? AppColors.primaryFrances
                                : AppColors.greyMedio,
                            BlendMode.srcIn,
                          ),
                          width: AppSpacing.iconSizeSmall,
                          height: AppSpacing.iconSizeSmall,
                        ),
                        onTap: () async {
                          final result = await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            barrierColor: AppColors.overlayBlack,
                            builder: (context) => AnimalFilterModal(
                              initialSex: _currentFilterSex,
                              initialFamilies: _currentFilterFamilies,
                              initialAges: _currentFilterAges,
                            ),
                          );
                          
                          if (!context.mounted) return;

                          if (result != null) {
                            setState(() {
                              _currentFilterSex = result['sex'] as String? ?? 'Ambos';
                              _currentFilterFamilies = result['families'] as List<String>? ?? [];
                              _currentFilterAges = result['ages'] as List<String>? ?? [];
                            });

                            final Map<String, dynamic> queryParams = {};
                            
                            final sex = result['sex'] as String?;
                            if (sex != null && sex != 'Ambos') {
                              if (sex == 'Macho') {
                                queryParams['sex'] = 'MALE';
                              } else if (sex == 'Hembra') {
                                queryParams['sex'] = 'FEMALE';
                              } else {
                                queryParams['sex'] = sex;
                              }
                            }

                            final families = result['families'] as List<String>?;
                            if (families != null && families.isNotEmpty) {
                              final mappedFamilies = families.map((family) {
                                switch (family) {
                                  case 'Felino': return 'CAT';
                                  case 'Canino': return 'DOG';
                                  case 'Bovino': return 'COW';
                                  case 'Equino': return 'HORSE';
                                  default: return family;
                                }
                              }).toList();
                              // API takes string, we can join with comma or just send the first
                              queryParams['species'] = mappedFamilies.join(',');
                            }

                            final ages = result['ages'] as List<String>?;
                            if (ages != null && ages.isNotEmpty) {
                              int? globalMin;
                              int? globalMax;
                              bool hasUnboundedMax = false;

                              for (final ageStr in ages) {
                                int min = 0;
                                int? max;
                                switch (ageStr) {
                                  case '0-6 meses': min = 0; max = 6; break;
                                  case '7-11 meses': min = 7; max = 11; break;
                                  case '1-3 años': min = 12; max = 36; break;
                                  case '4-6 años': min = 48; max = 72; break;
                                  case '7-10 años': min = 84; max = 120; break;
                                  case '11-15 años': min = 132; max = 180; break;
                                  case '16-20 años': min = 192; max = 240; break;
                                  case '21-25 años': min = 252; max = 300; break;
                                  case '+25 años': min = 301; max = null; break;
                                }
                                
                                if (globalMin == null || min < globalMin) {
                                  globalMin = min;
                                }
                                if (max == null) {
                                  hasUnboundedMax = true;
                                } else if (!hasUnboundedMax) {
                                  if (globalMax == null || max > globalMax) {
                                    globalMax = max;
                                  }
                                }
                              }
                              
                              if (globalMin != null) queryParams['minAgeMonths'] = globalMin;
                              if (!hasUnboundedMax && globalMax != null) {
                                queryParams['maxAgeMonths'] = globalMax;
                              }
                            }
                            
                            if (queryParams.isEmpty) {
                              // If no filters were selected or they were cleared, reload without filters
                              if (context.read<AnimalCubit>().currentOwnerId != null) {
                                // Since we already loaded, let's just force a reload by setting internal state or fetching again.
                                // searchAnimals with empty query params will naturally just fetch by ownerId.
                                context.read<AnimalCubit>().searchAnimals(queryParams);
                              }
                            } else {
                              context.read<AnimalCubit>().searchAnimals(queryParams);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.m),

                // Grouped animals
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                          ),
                          children: grouped.entries
                              .map(
                                (entry) => _buildGroup(entry.key, entry.value),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),

            // FAB — bottom right
            Positioned(
              right: AppSpacing.l,
              bottom: AppSpacing.l,
              child: _buildFab(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSpacing.iconSizeMedium,
        height: AppSpacing.iconSizeMedium,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.greyDelineante),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1925).withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGroup(String family, List<AnimalModel> animals) {
    final bool isCollapsed = _collapsedFamilies.contains(family);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        GestureDetector(
          onTap: () {
            setState(() {
              if (isCollapsed) {
                _collapsedFamilies.remove(family);
              } else {
                _collapsedFamilies.add(family);
              }
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyDelineante, width: 2),
              ),
            ),
            height: AppSpacing.xxxl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(family, style: AppTypography.heading2.copyWith()),
                RotatedBox(
                  quarterTurns: isCollapsed ? 0 : 1, // 0 = right (collapsed), 1 = down (expanded)
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

        if (!isCollapsed) ...[
          if (_viewMode == AnimalCardMode.grid)
            const SizedBox(height: AppSpacing.m),
          _viewMode == AnimalCardMode.grid
              ? _buildGroupGrid(animals)
              : _buildGroupList(animals),
        ],

        const SizedBox(height: AppSpacing.l),
      ],
    );
  }

  Widget _buildGroupGrid(List<AnimalModel> animals) {
    return SizedBox(
      height: 131,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: animals.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 103,
              child: AnimalCard(
                animal: animals[index],
                mode: AnimalCardMode.grid,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.animalDetail,
                    arguments: animals[index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupList(List<AnimalModel> animals) {
    return Column(
      children: animals.map((animal) {
        return AnimalCard(
          animal: animal,
          mode: AnimalCardMode.compactList,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.animalDetail,
              arguments: animal,
            );
          },
          onMenuTap: () {
            // TODO: Show animal options
          },
        );
      }).toList(),
    );
  }

  Widget _buildFab(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'agregar') {
          showAnimalCreationModal(context);
        } else if (value == 'transferir') {
          // TODO: Implement transfer
        }
      },
      offset: const Offset(0, -115),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
      ),
      constraints: const BoxConstraints(minWidth: 203, maxWidth: 203),
      color: AppColors.white,
      elevation: 4,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'agregar',
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/add-circle.svg',
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
              ),
              const SizedBox(width: 10),
              Text(
                'Agregar animal',
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'transferir',
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/vuesax-bold-send-sqaure-2.svg',
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
              ),
              const SizedBox(width: 10),
              Text(
                'Transferir animales',
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: AppSpacing.iconSizeMedium,
        height: AppSpacing.iconSizeMedium,
        decoration: BoxDecoration(
          color: AppColors.secondaryCoral,
          borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryCoral.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.white,
          size: AppSpacing.iconSizeSmall,
        ),
      ),
    );
  }

  String _pluralizeFamily(String family) {
    // Canino → Caninos, Felino → Felinos, etc.
    if (family.endsWith('o')) {
      return '${family}s';
    }
    return family;
  }
}
