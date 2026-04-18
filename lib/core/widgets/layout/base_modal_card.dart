import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/constants/app_icons.dart';

/// Reusable floating modal card that appears centered as an overlay dialog.
///
/// Use [showBaseModalCard] to present this modal on top of any screen.
///
/// Example usage:
/// ```dart
/// showBaseModalCard(
///   context: context,
///   builder: (context) => BaseModalCard(
///     title: 'Transferir animales',
///     subtitle: '0 seleccionados',
///     onClose: () => Navigator.pop(context),
///     bottomChild: CustomButton(text: 'Transferir', onPressed: () {}),
///     child: MyContent(),
///   ),
/// );
/// ```
void showBaseModalCard({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
}) {
  showDialog(
    context: context,
    barrierColor: AppColors.overlayBlack,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

class BaseModalCard extends StatelessWidget {
  /// Main title displayed centered in the header.
  final String title;

  /// Optional subtitle below the title (e.g. "Familia - 1 de 3").
  final Widget? subtitle;

  /// Content body of the modal.
  final Widget child;

  /// Called when the close (X) button is tapped.
  /// Defaults to `Navigator.pop(context)`.
  final VoidCallback? onClose;

  /// Called when the back (←) button is tapped.
  /// If null, the back button is hidden.
  final VoidCallback? onBack;

  /// Whether to show the back arrow button in the header.
  final bool showBackButton;

  /// Optional widget fixed at the bottom of the modal (e.g. a button).
  final Widget? bottomChild;

  /// Whether the child content should be scrollable with a custom scrollbar.
  final bool scrollable;

  /// Horizontal padding applied to the scrollable content area.
  final double contentHorizontalPadding;

  const BaseModalCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onClose,
    this.onBack,
    this.showBackButton = false,
    this.bottomChild,
    this.scrollable = false,
    this.contentHorizontalPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 343,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 160,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorders.medium(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // — Header —
                _buildHeader(context),

                // — Content —
                Flexible(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Navigation row: back / close icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              if (showBackButton)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.pop(context),
                  child: SvgPicture.asset(
                    AppIcons.arrowLeft,
                    colorFilter: const ColorFilter.mode(
                      AppColors.greyNegro,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                )
              else
                const SizedBox(width: 24),

              // Close button
              GestureDetector(
                onTap: onClose ?? () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: AppColors.greyNegro,
                  size: 24,
                ),
              ),
            ],
          ),

          // Title
          Text(
            title,
            style: AppTypography.body3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.greyNegro,
            ),
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            subtitle!,
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // With bottom fixed button
    if (bottomChild != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: scrollable ? _buildScrollableChild() : child,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: bottomChild!,
          ),
        ],
      );
    }

    // Without bottom button
    if (scrollable) {
      return Flexible(child: _buildScrollableChild());
    }

    return child;
  }

  Widget _buildScrollableChild() {
    return RawScrollbar(
      thumbColor: AppColors.primaryIndigo,
      trackColor: AppColors.greyDelineante,
      radius: const Radius.circular(AppBorders.radiusSmall),
      thickness: 2,
      trackVisibility: true,
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          contentHorizontalPadding, 0, contentHorizontalPadding, 16,
        ),
        child: child,
      ),
    );
  }
}
