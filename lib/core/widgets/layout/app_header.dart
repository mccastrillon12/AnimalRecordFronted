import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_back_button.dart';
import '../buttons/app_close_button.dart';
import '../../theme/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Color backgroundColor;
  final Color contentColor;
  final Widget? customTrailing;
  final bool showCloseText;

  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = true,
    this.showCloseButton = false,
    this.onBack,
    this.onClose,
    this.backgroundColor = Colors.transparent,
    this.contentColor = Colors.white,
    this.customTrailing,
    this.showCloseText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            AppBackButton(onPressed: onBack, color: contentColor)
          else
            const SizedBox(width: 48, height: 48),

          if (title != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title!,
                  style: AppTypography.heading2.copyWith(color: AppColors.greyTextos),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          
          if (customTrailing != null)
             customTrailing!
          else if (showCloseButton)
            AppCloseButton(
              onClose: onClose, 
              contentColor: contentColor,
              showText: showCloseText,
            )
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}
