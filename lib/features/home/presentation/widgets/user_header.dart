import 'package:flutter/material.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundDegrade),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 168,
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxxl, bottom: 0),
            child: Image.asset(
              'assets/Logo/Imagotipo_blanco.png',
              width: 40,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        String name = '';
                        String? profilePic;
                        if (state is AuthSuccess) {
                          name = state.user.name;
                          profilePic = state.user.profilePicture;
                        }

                        if (profilePic != null && profilePic.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: profilePic,
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (context, url) =>
                                  _buildInitials(name),
                              errorWidget: (context, url, error) =>
                                  _buildInitials(name),
                            ),
                          );
                        }

                        return _buildInitials(name);
                      },
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (previous, current) {
                      if (current is AuthSuccess || previous is AuthSuccess) {
                        return true;
                      }
                      return false;
                    },
                    builder: (context, state) {
                      String name = 'Usuario';
                      String role = 'Propietario';

                      if (state is AuthSuccess) {
                        name = state.user.name;
                        if (state.user.roles.isNotEmpty) {
                          role = state.user.roles.first == 'PROPIETARIO_MASCOTA'
                              ? 'Propietario'
                              : state.user.roles.first;
                        }
                      }

                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 21,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Hola, ',
                                        style: AppTypography.heading2.copyWith(
                                          color: AppColors.white.withOpacity(
                                            0.54,
                                          ),
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _formatName(name),
                                        style: AppTypography.heading2.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Container(
                              height: 21,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                role,
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.primaryAzulClaro,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: 42,
                  height: 42,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/icons/notification.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () {},
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatName(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final limitedParts = parts.take(3);

    final formattedParts = limitedParts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return formattedParts.join(' ');
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: AppTypography.heading1.copyWith(color: AppColors.white),
      ),
    );
  }
}
