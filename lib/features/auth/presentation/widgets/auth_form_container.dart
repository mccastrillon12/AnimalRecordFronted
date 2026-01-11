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

  const AuthFormContainer({
    super.key,
    required this.child,
    this.onBack,
    this.onCancel,
    this.showLogo = true,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOxford,
      body: SafeArea(
        child: Column(
          children: [
            // Header con flecha y Cancelar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 48),
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
                      width: 100,
                    ), // Espaciador para mantener equilibrio
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Logo Placeholder
            if (showLogo) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '.AR',
                    style: AppTypography.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
