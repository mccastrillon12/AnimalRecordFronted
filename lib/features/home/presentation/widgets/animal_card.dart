import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';

/// Display mode for the animal card.
enum AnimalCardMode { list, grid, compactList, detailHeader }

/// A reusable card for displaying an animal.
///
/// Supports three layouts:
/// - [AnimalCardMode.list]: Horizontal row with photo, name, age, code, sex tag.
/// - [AnimalCardMode.grid]: Vertical column with photo, name, code.
/// - [AnimalCardMode.compactList]: Flat row with photo, name, code, context menu.
class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final AnimalCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const AnimalCard({
    super.key,
    required this.animal,
    this.mode = AnimalCardMode.list,
    this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: switch (mode) {
        AnimalCardMode.list => _buildListCard(),
        AnimalCardMode.grid => _buildGridCard(),
        AnimalCardMode.compactList => _buildCompactListCard(),
        AnimalCardMode.detailHeader => _buildDetailHeader(),
      },
    );
  }

  // ===========================================================================
  // LIST MODE — horizontal row card
  // ===========================================================================

  Widget _buildListCard() {
    return Container(
      height: 99,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.large(),
        border: Border.all(color: AppColors.greyDelineante, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          _buildPhoto(size: 52, borderRadius: AppBorders.radiusMedium),

          const SizedBox(width: 16),

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
                        style: AppTypography.body5.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      ),
                    ],
                  ],
                ),

                // Code
                Text(
                  animal.code,
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),

                if (animal.sexDisplay.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.greyDelineante,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        animal.sexDisplay,
        style: AppTypography.body5.copyWith(
          color: AppColors.greyTextos,
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
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.large(),
        border: Border.all(color: AppColors.greyDelineante, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          _buildPhoto(size: 52, borderRadius: AppBorders.radiusMedium),

          const SizedBox(height: 8),

          // Name
          Text(
            animal.name,
            style: AppTypography.body3.copyWith(color: AppColors.greyNegro),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),

          // Code
          Text(
            animal.code,
            style: AppTypography.body5.copyWith(color: AppColors.greyBordes),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMPACT LIST MODE — flat row for "Mis Animales"
  // ===========================================================================

  Widget _buildCompactListCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.greyDelineante, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Photo
          _buildPhoto(size: 52, borderRadius: AppBorders.radiusMedium),

          const SizedBox(width: 12),

          // Name + Code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  animal.name,
                  style: AppTypography.body3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyNegro,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  animal.code,
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
                  ),
                ),
              ],
            ),
          ),

          // Context menu
          GestureDetector(
            onTap: onMenuTap,
            child: SvgPicture.asset(
              'assets/icons/icon_ContextMenu.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.greyMedio,
                BlendMode.srcIn,
              ),
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
              child: CachedNetworkImage(
                imageUrl: animal.imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (context, url) => _buildPlaceholderIcon(size),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(size),
              ),
            )
          : _buildPlaceholderIcon(size),
    );
  }

  Widget _buildPlaceholderIcon(double size) {
    return Center(
      child: Icon(Icons.pets, color: AppColors.greyBordes, size: size * 0.5),
    );
  }

  // ===========================================================================
  // DETAIL HEADER MODE — large card with full-bleed image and gradient overlay
  // ===========================================================================

  Widget _buildDetailHeader() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.greyDelineante,
        borderRadius: AppBorders.large(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (animal.imageUrl != null)
            CachedNetworkImage(
              imageUrl: animal.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildDetailPlaceholder(),
              errorWidget: (context, url, error) => _buildDetailPlaceholder(),
            )
          else
            _buildDetailPlaceholder(),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Text content
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        animal.name,
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal.code,
                        style: AppTypography.body5.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (animal.ageDisplay.isNotEmpty)
                  Text(
                    animal.ageDisplay,
                    style: AppTypography.body3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPlaceholder() {
    return Container(
      color: AppColors.primaryIndigo.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.pets, color: AppColors.greyBordes, size: 64),
      ),
    );
  }
}
