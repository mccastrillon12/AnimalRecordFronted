import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/widgets/biometric_disable_dialog.dart';
import 'package:animal_record/features/auth/presentation/widgets/biometric_enable_dialog.dart';
import 'package:animal_record/features/auth/presentation/pages/biometric_activation_screen.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/layout/app_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        if (state is AuthSuccess && state.biometricUpdateSuccess) {
          if (!state.isBiometricEnabled) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ErrorDisplay.showSuccess(
              context,
              'Biometría desactivada exitosamente.',
            );
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.bgOxford,
          body: Stack(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) {
                return current is AuthSuccess;
              },
              builder: (context, state) {
                String name = 'Usuario';
                String displayContact = '';
                String role = 'Propietario';

                if (state is AuthSuccess) {
                  name = state.user.name;
                  if (state.user.authMethod == 'PHONE') {
                    displayContact = state.user.cellPhone;
                  } else {
                    displayContact = state.user.email;
                  }

                  if (state.user.roles.isNotEmpty) {
                    role = state.user.roles.first == 'PROPIETARIO_MASCOTA'
                        ? 'Propietario'
                        : state.user.roles.first;
                  }
                }

                return SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: AppHeader(),
                        ),

                        Column(
                          children: [
                            Text(
                              role,
                              style: AppTypography.body4.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.l),

                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.primaryIndigo,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Center(
                                child:
                                    state is AuthSuccess &&
                                        state.user.profilePicture != null &&
                                        state.user.profilePicture!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: state.user.profilePicture!,
                                        fit: BoxFit.cover,
                                        width: 96,
                                        height: 96,
                                        fadeInDuration: Duration.zero,
                                        fadeOutDuration: Duration.zero,
                                        placeholder: (context, url) => Text(
                                          _getInitials(name),
                                          style: AppTypography.heading1
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 32,
                                              ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Text(
                                              _getInitials(name),
                                              style: AppTypography.heading1
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                  ),
                                            ),
                                      )
                                    : Text(
                                        _getInitials(name),
                                        style: AppTypography.heading1.copyWith(
                                          color: Colors.white,
                                          fontSize: 32,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Container(
                              height: 30,
                              alignment: Alignment.center,
                              child: Text(
                                _formatName(name),
                                style: AppTypography.heading1.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              height: 21,
                              alignment: Alignment.center,
                              child: Text(
                                displayContact,
                                style: AppTypography.body4.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: 'assets/icons/bold-people.svg',
                                label: 'Cambiar perfil',
                                onTap: () {},
                              ),
                              _buildActionButton(
                                icon: 'assets/icons/Edit.svg',
                                label: 'Editar perfil',
                                onTap: () {
                                  Navigator.pushNamed(context, '/edit-profile');
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        _buildOptionsList(context, state),
                        const SizedBox(height: AppSpacing.xl),

                        Image.asset(
                          'assets/Logo/Imagotipo_blanco.png',
                          height: 24,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ANIMAL RECORD',
                          style: AppTypography.body3.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                );
              },
            ),

            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: icon is String
                ? SvgPicture.asset(
                    icon,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.body6.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final textColor = color ?? const Color(0xFF59667A);
    return SizedBox(
      height: 56,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ListTile(
                onTap: onTap,
                leading: icon is String
                    ? SvgPicture.asset(
                        icon,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          textColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, color: textColor),
                title: Text(
                  label,
                  style: AppTypography.body3.copyWith(
                    color: color ?? const Color(0xFF2E3949),
                  ),
                ),
                trailing: SvgPicture.asset(
                  'assets/icons/arrow-right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    color ?? const Color(0xFF0072BB),
                    BlendMode.srcIn,
                  ),
                ),
                contentPadding: const EdgeInsets.only(left: 15, right: 24),
                dense: true,
                visualDensity: const VisualDensity(vertical: -4),
              ),
            ),
          ),
        ],
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

  Widget _buildOptionsList(BuildContext context, AuthState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildOptionTile(
              icon: 'assets/icons/bold-frame.svg',
              label: 'Mi cuenta',
              onTap: () {
                Navigator.pushNamed(context, '/my-account');
              },
            ),
            Divider(color: AppColors.greyClaro, height: 1),
            _buildOptionTile(
              icon: 'assets/icons/notification.svg',
              label: 'Notificaciones',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: 'assets/icons/Language.svg',
              label: 'Idiomas',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: 'assets/icons/scan-eye.svg',
              label: 'Ingreso con biometría',
              onTap: () {
                if (state is AuthSuccess &&
                    state.isBiometricEnabled) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        BiometricDisableDialog(
                          onDisable: () {
                            context.read<AuthBloc>().add(
                              UpdateBiometricStatusRequested(
                                false,
                              ),
                            );
                          },
                        ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => BiometricEnableDialog(
                      onEnable: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BiometricActivationScreen(),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            Divider(color: AppColors.greyClaro, height: 1),
            _buildOptionTile(
              icon: 'assets/icons/Help.svg',
              label: 'Centro de ayuda',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: 'assets/icons/Terms.svg',
              label: 'Términos y Políticas',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: 'assets/icons/logout.svg',
              label: 'Cerrar sesión',
              color: const Color(0xFFF26F49),
              onTap: () {
                context.read<AuthBloc>().add(
                  LogoutRequested(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
