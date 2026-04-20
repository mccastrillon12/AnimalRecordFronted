import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_card.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_creation_modal.dart';

class AnimalsSection extends StatefulWidget {
  final VoidCallback? onViewAll;

  const AnimalsSection({super.key, this.onViewAll});

  @override
  State<AnimalsSection> createState() => _AnimalsSectionState();
}

class _AnimalsSectionState extends State<AnimalsSection> {
  AnimalCardMode _viewMode = AnimalCardMode.grid;

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
        final List<AnimalModel> animals;
        if (state is AnimalsLoaded) {
          animals = state.animals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalCreated) {
          animals = state.allAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalCreating) {
          animals = state.existingAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else if (state is AnimalError) {
          animals = state.existingAnimals
              .map((e) => AnimalModel.fromEntity(e))
              .toList();
        } else {
          animals = [];
        }

        if (state is AnimalsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasAnimals = animals.isNotEmpty;
        // Max 3 in home preview
        final previewAnimals = animals.length > 3
            ? animals.sublist(0, 3)
            : animals;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis animales',
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasAnimals)
                    _buildViewToggle()
                  else
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Ver todos',
                        style: AppTypography.body3.copyWith(
                          color: AppColors.primaryFrances.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              if (hasAnimals) ...[
                const SizedBox(height: 16),
                _viewMode == AnimalCardMode.grid
                    ? _buildGridView(previewAnimals)
                    : _buildListView(previewAnimals),
                const SizedBox(height: 8),
                // "Ver todos" link
                Align(
                  alignment: _viewMode == AnimalCardMode.list
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: GestureDetector(
                    onTap: widget.onViewAll,
                    child: Text(
                      'Ver todos',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.primaryFrances,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 64),
                _buildEmptyState(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewToggle() {
    return GestureDetector(
      onTap: _toggleViewMode,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: SvgPicture.asset(
            _viewMode == AnimalCardMode.list
                ? 'assets/icons/vuesax-bold-element-3.svg'
                : 'assets/icons/vuesax-bold-fatrows.svg',
            colorFilter: ColorFilter.mode(AppColors.greyMedio, BlendMode.srcIn),
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<AnimalModel> animals) {
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
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(List<AnimalModel> animals) {
    return Column(
      children: animals
          .map(
            (animal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimalCard(
                animal: animal,
                mode: AnimalCardMode.list,
                onTap: () {},
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No tienes ningún animal registrado todavía.',
              textAlign: TextAlign.center,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
            const SizedBox(height: 4),
            Text(
              'Empieza agregando uno desde',
              textAlign: TextAlign.center,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              width: 128,
              height: 39,
              child: ElevatedButton(
                onPressed: () => showAnimalCreationModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '+ Animal',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
