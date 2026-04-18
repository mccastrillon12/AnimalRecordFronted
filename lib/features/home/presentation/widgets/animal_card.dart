import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/features/home/domain/models/animal_model.dart';

/// Display mode for the animal card.
enum AnimalCardMode { list, grid }

/// A reusable card for displaying an animal.
///
/// Supports two layouts:
/// - [AnimalCardMode.list]: Horizontal row with photo, name, age, code, sex tag.
/// - [AnimalCardMode.grid]: Vertical column with photo, name, code.
class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final AnimalCardMode mode;
  final VoidCallback? onTap;

  const AnimalCard({
    super.key,
    required this.animal,
    this.mode = AnimalCardMode.list,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: mode == AnimalCardMode.list ? _buildListCard() : _buildGridCard(),
    );
  }

  // ===========================================================================
  // LIST MODE — horizontal row card
  // ===========================================================================

  Widget _buildListCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.large(),
        border: Border.all(color: AppColors.greyDelineante, width: 1),
      ),
      child: Row(
        children: [
          // Photo
          _buildPhoto(size: 60, borderRadius: AppBorders.radiusMedium),

          const SizedBox(width: AppSpacing.s),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name + Age
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        animal.name,
                        style: AppTypography.body3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.greyNegro,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (animal.ageDisplay.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        animal.ageDisplay,
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyTextos,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 2),

                // Code
                Text(
                  animal.code,
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),

                if (animal.sexDisplay.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Sex tag
                  _buildSexTag(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgHielo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        animal.sexDisplay,
        style: AppTypography.body6.copyWith(
          color: AppColors.primaryFrances,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ===========================================================================
  // GRID MODE — vertical column card
  // ===========================================================================

  Widget _buildGridCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.large(),
        border: Border.all(color: AppColors.greyDelineante, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          _buildPhoto(size: 72, borderRadius: AppBorders.radiusMedium),

          const SizedBox(height: 8),

          // Name
          Text(
            animal.name,
            style: AppTypography.body3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.greyNegro,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          const SizedBox(height: 2),

          // Code
          Text(
            animal.code,
            style: AppTypography.body6.copyWith(
              color: AppColors.greyBordes,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED — photo widget
  // ===========================================================================

  Widget _buildPhoto({required double size, required double borderRadius}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.greyDelineante,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: animal.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.network(
                animal.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon(size);
                },
              ),
            )
          : _buildPlaceholderIcon(size),
    );
  }

  Widget _buildPlaceholderIcon(double size) {
    return Center(
      child: Icon(
        Icons.pets,
        color: AppColors.greyBordes,
        size: size * 0.5,
      ),
    );
  }
}
