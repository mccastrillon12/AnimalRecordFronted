import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class CustomSnackBar extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onClose;

  const CustomSnackBar({
    super.key,
    required this.message,
    this.isError = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isError
        ? AppColors.bgRosa
        : const Color(0xFFF0FFF7); // Mint-ish green
    final borderColor = isError
        ? AppColors.errorRojo
        : AppColors.successEsmeralda;
    final iconColor = isError
        ? AppColors.errorRojo
        : AppColors.successEsmeralda;
    final iconData = isError ? Icons.cancel : Icons.check_circle;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: AppBorders.medium(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center text vertically with icon
        children: [
          // Icon Container
          Container(
            // Margin removed as we want verified centering
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.m),
          // check if message is short logic? For now standard
          Expanded(
            child: Text(
              message,
              style: AppTypography.body5.copyWith(
                color: AppColors.greyNegro,
                fontWeight: FontWeight.w600,
                height: 1.5, // Added spacing between lines
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: AppSpacing.s),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, color: AppColors.greyIconos, size: 20),
            ),
          ] else
            // Always show close button? User requested "close button" in screenshot is distinct.
            // Screenshot has an 'X' on top right.
            // Let's just always show it or auto-dismiss.
            // But SnackBar handles dismissal.
            // The close button is visual.
            const SizedBox(width: AppSpacing.s),
          const Icon(
            Icons.close,
            color: Colors
                .transparent, // Placeholder for alignment if needed or just remove
            size: 20,
          ),
        ],
      ),
    );
  }
}
