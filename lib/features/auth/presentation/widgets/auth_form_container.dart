import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class AuthFormContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final bool showLogo;
  final bool showCancelButton;
  final String? title;
  final Widget? subtitle;
  final bool addInternalPadding;

  const AuthFormContainer({
    super.key,
    required this.child,
    this.onBack,
    this.onCancel,
    this.showLogo = true,
    this.showCancelButton = true,
    this.title,
    this.subtitle,
    this.addInternalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgOxford,
      body: SafeArea(
        child: Column(
          children: [
            // Header con flecha, logo y Cancelar
            Transform.translate(
              offset: const Offset(0, 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: onBack,
                      )
                    else
                      const SizedBox(width: 48, height: 48),

                    // Logo centrado cuando no hay botón cancelar
                    if (!showCancelButton && showLogo)
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/Logo/Imagotipo_blanco.png',
                            width: 40,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    if (showCancelButton)
                      GestureDetector(
                        onTap: onCancel ?? () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Text(
                              'Cancelar',
                              style: AppTypography.body4.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.close, color: Colors.white),
                          ],
                        ),
                      )
                    else
                      const SizedBox(
                        width: 48,
                        height: 48,
                      ), // Espaciador para mantener equilibrio
                  ],
                ),
              ),
            ),
            const SizedBox(height: 56),
            // Logo Placeholder (solo cuando hay botón cancelar)
            if (showLogo && showCancelButton) ...[
              Center(
                child: Image.asset(
                  'assets/Logo/Imagotipo_blanco.png',
                  width: 40,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
            // Contenido Blanco
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.greyBlanco,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Title and subtitle section (optional)
                    if (title != null || subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.xxl,
                          right: AppSpacing.l,
                          left: AppSpacing.l,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (title != null)
                              SizedBox(
                                height: AppSpacing.registerTitleHeight,
                                child: Text(
                                  title!,
                                  style: AppTypography.heading1,
                                ),
                              ),
                            if (subtitle != null)
                              SizedBox(
                                height: AppSpacing.registerSubtitleHeight,
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                    // Content area
                    Expanded(
                      child: addInternalPadding
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.l,
                              ),
                              child: child,
                            )
                          : child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
