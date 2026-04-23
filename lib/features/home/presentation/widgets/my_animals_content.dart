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
                          colorFilter: const ColorFilter.mode(
                            AppColors.greyMedio,
                            BlendMode.srcIn,
                          ),
                          width: AppSpacing.iconSizeSmall,
                          height: AppSpacing.iconSizeSmall,
                        ),
                        onTap: () {
                          // TODO: Implement filter
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.greyDelineante, width: 2),
            ),
          ),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(family, style: AppTypography.heading2.copyWith()),
              SvgPicture.asset(
                'assets/icons/arrow-right.svg',
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
              ),
            ],
          ),
        ),

        if (_viewMode == AnimalCardMode.grid)
          const SizedBox(height: AppSpacing.m),
        _viewMode == AnimalCardMode.grid
            ? _buildGroupGrid(animals)
            : _buildGroupList(animals),

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
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
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
