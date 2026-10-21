import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'fixed_bottom_action_layout.dart';

const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness:
      Brightness.light, // iconos blancos sobre fondo oscuro
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
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry? titlePadding;
  final double? trailingTop;
  final double? trailingRight;
  final Color? bottomSafeAreaColor;
  final Color? backgroundColor;

  /// Si es true, el título se fija en su posición y no hace scroll.
  final bool fixedTitle;

  /// Widget adicional fijo debajo del título (solo cuando fixedTitle es true).
  final Widget? fixedHeaderChild;

  /// Altura total del área fija del header (título + fixedHeaderChild) para calcular el padding del scroll.
  final double fixedHeaderHeight;
  final ScrollController? scrollController;
  final bool expandFixedBody;

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
    this.titleStyle,
    this.titlePadding,
    this.trailingTop,
    this.trailingRight,
    this.bottomSafeAreaColor,
    this.backgroundColor,
    this.fixedTitle = false,
    this.fixedHeaderChild,
    this.fixedHeaderHeight = 0,
    this.scrollController,
    this.expandFixedBody = false,
  });

  Widget _buildTrailingBackground(BuildContext context) {
    final double top = trailingTop ?? 24;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: top + 24 + top,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingContent(BuildContext context) {
    return Positioned(
      top: trailingTop ?? 24,
      right: trailingRight ?? 24,
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
    if (title.isEmpty && titleStyle?.fontSize == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: titlePadding ?? const EdgeInsets.only(top: 96, bottom: 24),
      child: Center(
        child: Text(title, style: titleStyle ?? AppTypography.heading1),
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
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Colors.white,
                      borderRadius: const BorderRadius.only(
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
                          child: LayoutBuilder(
                            builder: (context, viewportConstraints) {
                              Widget content = SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    if (!fixedTitle) _buildHeaderTitle(),
                                    if (fixedTitle)
                                      SizedBox(height: fixedHeaderHeight),
                                    if (expandFixedBody)
                                      Expanded(child: child)
                                    else
                                      child,
                                  ],
                                ),
                              );

                              if (expandFixedBody) {
                                content = ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: viewportConstraints.maxHeight,
                                  ),
                                  child: IntrinsicHeight(child: content),
                                );
                              }

                              return SingleChildScrollView(
                                controller: scrollController,
                                physics: physics,
                                child: content,
                              );
                            },
                          ),
                        ),
                        if (fixedTitle)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: backgroundColor ?? Colors.white,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeaderTitle(),
                                  if (fixedHeaderChild != null)
                                    fixedHeaderChild!,
                                ],
                              ),
                            ),
                          ),
                        _buildTrailingBackground(context),
                        _buildTrailingContent(context),
                        if (headerChildren != null) ...headerChildren!,
                      ],
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: bottomSafeAreaColor ?? AppColors.greyBlanco,
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
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: scrollController,
                        physics: physics,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 100,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!fixedTitle) _buildHeaderTitle(),
                                if (fixedTitle)
                                  SizedBox(height: fixedHeaderHeight),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (fixedTitle)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: backgroundColor ?? Colors.white,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeaderTitle(),
                                if (fixedHeaderChild != null) fixedHeaderChild!,
                              ],
                            ),
                          ),
                        ),
                      _buildTrailingBackground(context),
                      _buildTrailingContent(context),
                      if (headerChildren != null) ...headerChildren!,
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                color: bottomSafeAreaColor ?? AppColors.greyBlanco,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
