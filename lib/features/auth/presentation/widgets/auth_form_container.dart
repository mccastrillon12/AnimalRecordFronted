import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

import '../../../../core/widgets/buttons/app_back_button.dart';
import '../../../../core/widgets/buttons/app_close_button.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.bgOxford,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, 48),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.l),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (onBack != null)
                            AppBackButton(onPressed: onBack)
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
                            AppCloseButton(
                              onClose: onCancel,
                              contentColor: Colors.white,
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
                ],
              ),
            ),

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
                              Padding(
                                padding: const EdgeInsets.only(bottom: 0),
                                child: Text(
                                  title!,
                                  style: AppTypography.heading1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 8),
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
            // Relleno para asegurar que el blanco llegue hasta el final de la pantalla
            Container(
              height: MediaQuery.of(context).padding.bottom,
              color: AppColors.greyBlanco,
            ),
          ],
        ),
      ),
    );
  }
}
