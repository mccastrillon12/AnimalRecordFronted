import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String? description;
  final InlineSpan? richDescription;
  final Widget? content;
  final Widget? headerLeading;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final Color? titleColor;
  final bool isConfirmEnabled;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final double width;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.description,
    this.richDescription,
    this.content,
    this.headerLeading,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.confirmColor = const Color(0xFFFA2844),
    this.titleColor,
    this.isConfirmEnabled = true,
    required this.onConfirm,
    this.onCancel,
    this.onClose,
    this.width = 347,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  // Title
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      style: AppTypography.body3.copyWith(
                        color: titleColor ?? AppColors.greyTextos,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  if (description != null)
                    Text(
                      description!,
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyTextos,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.left,
                    )
                  else if (richDescription != null)
                    RichText(
                      text: TextSpan(
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyTextos,
                          height: 1.6,
                        ),
                        children: [richDescription!],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  if (description != null || richDescription != null)
                    const SizedBox(height: 16),
                  // Custom Content
                  if (content != null) ...[
                    content!,
                    const SizedBox(height: 16),
                  ],
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onCancel?.call();
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: Text(
                            cancelLabel,
                            style: AppTypography.body3.copyWith(
                              color: const Color(0xFF0072BB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isConfirmEnabled
                              ? () {
                                  Navigator.of(context).pop();
                                  onConfirm();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.greyDelineante,
                            disabledForegroundColor: AppColors.greyMedio,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            confirmLabel,
                            style: AppTypography.body3.copyWith(
                              color: isConfirmEnabled
                                  ? Colors.white
                                  : AppColors.greyMedio,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (headerLeading != null)
            Positioned(top: 16, left: 16, child: headerLeading!),
          // X close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.greyIconos),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
