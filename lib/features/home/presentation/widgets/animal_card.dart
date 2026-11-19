import 'package:animal_record/features/home/presentation/widgets/animal_status_tag.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_picture.dart';
import 'package:animal_record/features/home/presentation/utils/animal_picture.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_photo_edit.dart';

/// Display mode for the animal card.
enum AnimalCardMode { list, grid, compactList, detailHeader }

class AnimalAvatar extends StatelessWidget {
  final AnimalModel animal;
  final double size;
  final double borderRadius;
  final String? unknownFamilyIconPath;
  final ValueChanged<String>? onImageError;

  const AnimalAvatar({
    super.key,
    required this.animal,
    required this.size,
    required this.borderRadius,
    this.unknownFamilyIconPath,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgHielo,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimalPicture(
          animal: animal,
          width: size,
          height: size,
          iconSize: size * .5,
          onImageError: onImageError,
        ),
      ),
    );
  }
}

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
  final VoidCallback? onEditPhoto;
  final String? localPhotoPath;
  final bool photoDeleted;

  const AnimalCard({
    super.key,
    required this.animal,
    this.mode = AnimalCardMode.list,
    this.onTap,
    this.onMenuTap,
    this.onEditPhoto,
    this.localPhotoPath,
    this.photoDeleted = false,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1925).withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          _buildPhoto(size: 52, borderRadius: 8),

          const SizedBox(width: AppSpacing.m),

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
                      const SizedBox(width: AppSpacing.xxs),
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
                  const SizedBox(height: AppSpacing.xs),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
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
        borderRadius: AppBorders.medium(),
        border: Border.all(color: AppColors.greyDelineante, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1925).withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          _buildPhoto(size: 52, borderRadius: 8),

          const SizedBox(height: AppSpacing.xs),

          // Name
          Text(
            animal.name,
            style: AppTypography.body3,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),

          // Code
          Text(
            animal.code,
            style: AppTypography.body5.copyWith(color: AppColors.greyMedio),
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
      height: 63,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.greyDelineante, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo
          _buildPhoto(size: AppSpacing.xl, borderRadius: 5),

          const SizedBox(width: AppSpacing.s),

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
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  animal.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.greyMedio,
                  ),
                ),
              ],
            ),
          ),

          // Keep the existing row size and tag placement.
          if (!animal.isActive ||
              animal.transferStatus == 'PENDING' ||
              animal.transferStatus == 'TRANSFERRED')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!animal.isActive) AnimalStatusTag.inactive(),
                if (!animal.isActive &&
                    (animal.transferStatus == 'PENDING' ||
                        animal.transferStatus == 'TRANSFERRED'))
                  const SizedBox(width: 4),
                if (animal.transferStatus == 'PENDING')
                  AnimalStatusTag.pending(),
                if (animal.transferStatus == 'TRANSFERRED')
                  AnimalStatusTag.transferred(),
              ],
            )
          else if (animal.canWrite)
            GestureDetector(
              onTap: onMenuTap,
              child: SvgPicture.asset(
                'assets/icons/icon_ContextMenu.svg',
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
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
    return AnimalAvatar(animal: animal, size: size, borderRadius: borderRadius);
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
          if (localPhotoPath != null)
            Image.file(
              File(localPhotoPath!),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            )
          else if (!photoDeleted)
            ColoredBox(
              color: AppColors.bgHielo,
              child: AnimalPicture(
                animal: animal,
                width: double.infinity,
                height: 180,
                iconSize: 64,
              ),
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
          if (onEditPhoto != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: AnimalPhotoEditButton(onTap: onEditPhoto),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPlaceholder() {
    return Container(
      color: AppColors.bgHielo,
      child: Center(
        child: SvgPicture.asset(
          animalPictureIcon(
            species: animal.species,
            family: animal.family,
            code: animal.code,
          ),
          width: 64,
          height: 64,
          colorFilter: const ColorFilter.mode(
            AppColors.primaryFrances,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
