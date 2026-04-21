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
  final TextEditingController _searchController = TextEditingController();

  // Track collapsed groups
  final Set<String> _collapsedGroups = {};

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

  void _toggleGroup(String group) {
    setState(() {
      if (_collapsedGroups.contains(group)) {
        _collapsedGroups.remove(group);
      } else {
        _collapsedGroups.add(group);
      }
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
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Search bar + view toggle + filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppBorders.radiusMedium,
                            ),
                            border: Border.all(color: AppColors.greyDelineante),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: AppTypography.body4,
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              hintStyle: AppTypography.body4.copyWith(
                                color: AppColors.greyBordes,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.greyBordes,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

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
                          width: 24,
                          height: 24,
                        ),
                        onTap: _toggleViewMode,
                      ),

                      const SizedBox(width: 8),

                      // Filter button
                      _buildIconButton(
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.greyMedio,
                          size: 24,
                        ),
                        onTap: () {
                          // TODO: Implement filter
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
          border: Border.all(color: AppColors.greyDelineante),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGroup(String family, List<AnimalModel> animals) {
    final isCollapsed = _collapsedGroups.contains(family);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        GestureDetector(
          onTap: () => _toggleGroup(family),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.greyDelineante, width: 1),
              ),
            ),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  family,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.greyNegro,
                  ),
                ),
                Icon(
                  isCollapsed
                      ? Icons.chevron_right_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.greyBordes,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        if (!isCollapsed) ...[
          const SizedBox(height: 12),
          _viewMode == AnimalCardMode.grid
              ? _buildGroupGrid(animals)
              : _buildGroupList(animals),
        ],

        const SizedBox(height: 16),
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
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 107,
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
      offset: const Offset(0, -110),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorders.radiusMedium),
      ),
      color: AppColors.white,
      elevation: 4,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'agregar',
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryFrances,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Agregar animal',
                style: AppTypography.body3.copyWith(color: AppColors.greyNegro),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'transferir',
          child: Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primaryFrances,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Transferir animales',
                style: AppTypography.body3.copyWith(color: AppColors.greyNegro),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
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
          size: 24,
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
