import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthFormContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final bool showLogo;
  final bool showCancelButton;
  final String? title;
  final Widget? subtitle;
  final bool addInternalPadding;
  final double titleSpacing;

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
    this.titleSpacing = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgOxford,
      body: SafeArea(
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(0, 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onBack != null)
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/arrow-left.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: onBack,
                      )
                    else
                      const SizedBox(width: 48, height: 48),

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
                      const SizedBox(width: 48, height: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 56),

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
                            SizedBox(height: titleSpacing),
                            if (subtitle != null) subtitle!,
                          ],
                        ),
                      ),

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
