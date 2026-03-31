import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

class AppCloseButton extends StatelessWidget {
  final VoidCallback? onClose;
  final bool showText;
  final String text;
  final Color contentColor;

  const AppCloseButton({
    super.key,
    this.onClose,
    this.showText = true,
    this.text = 'Cancelar',
    this.contentColor = AppColors.greyTextos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.pop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showText) ...[
            Text(
              text,
              style: AppTypography.body4.copyWith(color: contentColor),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Icon(Icons.close, color: contentColor, size: 24),
        ],
      ),
    );
  }
}
