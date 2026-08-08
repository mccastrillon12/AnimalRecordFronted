import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppUserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const AppUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 52,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final photo = imageUrl?.trim() ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryIndigo,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo.isEmpty
          ? _initials()
          : CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              width: size,
              height: size,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, _) => _initials(),
              errorWidget: (_, _, _) => _initials(),
            ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        initialsForName(name),
        style: AppTypography.heading1.copyWith(
          color: AppColors.white,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

String initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
