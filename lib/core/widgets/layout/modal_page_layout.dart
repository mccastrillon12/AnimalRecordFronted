import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'fixed_bottom_action_layout.dart';

const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // iconos blancos sobre fondo oscuro
  statusBarBrightness: Brightness.dark,
);

class ModalPageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailingIcon;
  final List<Widget>? headerChildren;
  final Widget? bottomChild;
  final EdgeInsetsGeometry? bottomPadding;
  /// Si es true, el scroll solo se habilita cuando el teclado está visible.
  final bool scrollOnlyWithKeyboard;

  const ModalPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.trailingIcon,
    this.headerChildren,
    this.bottomChild,
    this.bottomPadding,
    this.scrollOnlyWithKeyboard = false,
  });

  Widget _buildTrailingContent(BuildContext context) {
    return Positioned(
      top: 32,
      right: 24,
      child:
          trailingIcon ??
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onClose ?? () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose ?? () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
    );
  }

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 96, bottom: 24),
      child: Center(
        child: Text(
          title,
          style: AppTypography.heading1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determina la física de scroll según el flag y la visibilidad del teclado
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final ScrollPhysics physics = scrollOnlyWithKeyboard && !keyboardOpen
        ? const NeverScrollableScrollPhysics()
        : const ClampingScrollPhysics();

    // Layout con botón fijo en la parte inferior
    if (bottomChild != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _statusBarStyle,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundDegrade,
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: const SizedBox(height: AppSpacing.l),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FixedBottomActionLayout(
                          padding: bottomPadding,
                          bottomChild: bottomChild!,
                          child: SingleChildScrollView(
                            physics: physics,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  _buildHeaderTitle(),
                                  child,
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildTrailingContent(context),
                        if (headerChildren != null) ...headerChildren!,
                      ],
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: AppColors.greyBlanco,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Layout scrollable sin botón fijo
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundDegrade,
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: const SizedBox(height: AppSpacing.l),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: physics,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 100,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_buildHeaderTitle(), child],
                            ),
                          ),
                        ),
                      ),
                      _buildTrailingContent(context),
                      if (headerChildren != null) ...headerChildren!,
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                color: AppColors.greyBlanco,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
