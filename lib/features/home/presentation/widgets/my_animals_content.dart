import 'package:flutter/material.dart';
import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';
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
import 'package:animal_record/features/home/presentation/widgets/animal_list_control_button.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';

/// Full "Mis Animales" page with search bar, grid/list toggle, filter, and
/// animals grouped by species (family).
class MyAnimalsContent extends StatefulWidget {
  final VoidCallback? onUploadCancelled;

  const MyAnimalsContent({super.key, this.onUploadCancelled});

  @override
  State<MyAnimalsContent> createState() => _MyAnimalsContentState();
}

class _MyAnimalsContentState extends State<MyAnimalsContent> {
  AnimalCardMode _viewMode = AnimalCardMode.grid;
  String _searchQuery = '';
  final Set<String> _collapsedFamilies = {};
  final TextEditingController _searchController = TextEditingController();
  String? _searchErrorText;

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
        final List<AnimalModel> inactiveAnimals = [];

        for (final animal in filtered) {
          if (!animal.isActive) {
            inactiveAnimals.add(animal);
          } else {
            final pluralFamily = pluralizeAnimalFamily(animal.family);
            grouped.putIfAbsent(pluralFamily, () => []);
            grouped[pluralFamily]!.add(animal);
          }
        }

        if (inactiveAnimals.isNotEmpty) {
          grouped['Transferidos e inactivos'] = inactiveAnimals;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: AppSpacing.iconSizeMedium,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: AppTypography.body4,
                                textAlignVertical: TextAlignVertical.center,
                                inputFormatters: [
                                  ErrorTriggeringTextInputFormatter(
                                    allowPattern: RegExp(r'^[a-zA-Z0-9\s]+$'),
                                    maxLength: 20,
                                    onError: (error) {
                                      if (_searchErrorText != error) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted)
                                                setState(
                                                  () =>
                                                      _searchErrorText = error,
                                                );
                                            });
                                      }
                                    },
                                    onSuccess: () {
                                      if (_searchErrorText != null) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted)
                                                setState(
                                                  () => _searchErrorText = null,
                                                );
                                            });
                                      }
                                    },
                                  ),
                                ],
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
                                    borderSide: BorderSide(
                                      color: _searchErrorText != null
                                          ? AppColors.error
                                          : const Color(0xFFA8AFBD),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                      color: _searchErrorText != null
                                          ? AppColors.error
                                          : const Color(0xFFA8AFBD),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                      color: _searchErrorText != null
                                          ? AppColors.error
                                          : const Color(0xFF0072BB),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchErrorText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _searchErrorText!,
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
                      ),

                      const SizedBox(width: AppSpacing.l),

                      // View toggle
                      AnimalListControlButton(
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
                      AnimalListControlButton(
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
                          final result =
                              await showModalBottomSheet<Map<String, dynamic>>(
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
                              _currentFilterSex =
                                  result['sex'] as String? ?? 'Ambos';
                              _currentFilterFamilies =
                                  result['families'] as List<String>? ?? [];
                              _currentFilterAges =
                                  result['ages'] as List<String>? ?? [];
                            });

                            final Map<String, dynamic> queryParams = {};

                            final sex = result['sex'] as String?;
                            if (sex != null) {
                              if (sex == 'Ambos') {
                                queryParams['sex'] = 'MALE,FEMALE';
                              } else {
                                queryParams['sex'] = sex == 'Macho'
                                    ? 'MALE'
                                    : 'FEMALE';
                              }
                            }

                            // Species: map to API codes and send comma-separated
                            final families =
                                result['families'] as List<String>?;
                            if (families != null && families.isNotEmpty) {
                              final mappedSpecies = families.map((family) {
                                switch (family) {
                                  case 'Felino':
                                    return 'CAT';
                                  case 'Canino':
                                    return 'DOG';
                                  case 'Bovino':
                                    return 'BOVINE';
                                  case 'Equino':
                                    return 'EQUINE';
                                  default:
                                    return family.toUpperCase();
                                }
                              }).toList();
                              queryParams['species'] = mappedSpecies.join(',');
                            }

                            // Age ranges: send each range individually as min-max in months
                            final ages = result['ages'] as List<String>?;
                            if (ages != null && ages.isNotEmpty) {
                              final List<String> ageRangeParts = [];

                              for (final ageStr in ages) {
                                switch (ageStr) {
                                  case '0-6 meses':
                                    ageRangeParts.add('0-6');
                                    break;
                                  case '7-11 meses':
                                    ageRangeParts.add('7-11');
                                    break;
                                  case '1-3 años':
                                    ageRangeParts.add('12-36');
                                    break;
                                  case '4-6 años':
                                    ageRangeParts.add('48-72');
                                    break;
                                  case '7-10 años':
                                    ageRangeParts.add('84-120');
                                    break;
                                  case '11-15 años':
                                    ageRangeParts.add('132-180');
                                    break;
                                  case '16-20 años':
                                    ageRangeParts.add('192-240');
                                    break;
                                  case '21-25 años':
                                    ageRangeParts.add('252-300');
                                    break;
                                  case '+25 años':
                                    ageRangeParts.add('301-600');
                                    break;
                                }
                              }

                              if (ageRangeParts.isNotEmpty) {
                                queryParams['ageRanges'] = ageRangeParts.join(
                                  ',',
                                );
                              }
                            }

                            if (queryParams.isEmpty) {
                              // If no filters were selected or they were cleared, reload without filters
                              if (context.read<AnimalCubit>().currentOwnerId !=
                                  null) {
                                context.read<AnimalCubit>().searchAnimals(
                                  queryParams,
                                );
                              }
                            } else {
                              context.read<AnimalCubit>().searchAnimals(
                                queryParams,
                              );
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
                          padding: const EdgeInsets.only(
                            left: AppSpacing.l,
                            right: AppSpacing.l,
                            bottom: 60, // Space for the FAB
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
                  quarterTurns: isCollapsed
                      ? 0
                      : 1, // 0 = right (collapsed), 1 = down (expanded)
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
      key: const Key('my-animals-actions-menu'),
      onSelected: (value) async {
        if (value == 'agregar') {
          showAnimalCreationModal(context);
        } else if (value == 'subir_documento') {
          final activeAnimals = context
              .read<AnimalCubit>()
              .animals
              .where((animal) => animal.isActive)
              .toList(growable: false);
          final uploaded = await Navigator.pushNamed(
            context,
            AppRoutes.sharedFileUpload,
            arguments: {
              'manualUpload': true,
              if (activeAnimals.length == 1)
                'preselectedAnimal': activeAnimals.single,
            },
          );
          if (!context.mounted || uploaded != false) return;
          final onUploadCancelled = widget.onUploadCancelled;
          if (onUploadCancelled != null) {
            onUploadCancelled();
          } else {
            ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
          }
        } else if (value == 'transferir') {
          // TODO: Implement transfer
        }
      },
      offset: const Offset(0, -162),
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
          value: 'subir_documento',
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/document-upload.svg',
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
              ),
              const SizedBox(width: 10),
              Text(
                'Subir archivo',
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
          borderRadius: BorderRadius.circular(6),
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
}
