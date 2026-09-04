import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_ai_feedback.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:flutter/material.dart';

class MedicalDocumentAiFeedbackBanner extends StatefulWidget {
  final VoidCallback? onDismissed;
  final Future<void> Function(MedicalDocumentAiFeedback feedback)? onSubmit;
  final bool initialHasResponded;
  final Future<void> Function()? onSubmitted;

  const MedicalDocumentAiFeedbackBanner({
    super.key,
    this.onDismissed,
    this.onSubmit,
    this.initialHasResponded = false,
    this.onSubmitted,
  });

  @override
  State<MedicalDocumentAiFeedbackBanner> createState() =>
      _MedicalDocumentAiFeedbackBannerState();
}

class _MedicalDocumentAiFeedbackBannerState
    extends State<MedicalDocumentAiFeedbackBanner> {
  late bool _hasResponded;
  bool _isDismissed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hasResponded = widget.initialHasResponded;
  }

  @override
  void didUpdateWidget(covariant MedicalDocumentAiFeedbackBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasResponded && widget.initialHasResponded) _hasResponded = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();
    if (_hasResponded) return _ThanksFeedback(onDismissed: _dismiss);
    return _FeedbackPrompt(
      isSubmitting: _isSubmitting,
      onDislike: () => _submitFeedback(MedicalDocumentAiFeedback.dislike),
      onLike: () => _submitFeedback(MedicalDocumentAiFeedback.like),
    );
  }

  Future<void> _submitFeedback(MedicalDocumentAiFeedback feedback) async {
    if (_isSubmitting || _hasResponded) return;
    setState(() => _isSubmitting = true);
    try {
      await (widget.onSubmit ?? _submitAiFeedback)(feedback);
      await widget.onSubmitted?.call();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _hasResponded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ErrorDisplay.showError(context, error.toString());
    }
  }

  Future<void> _submitAiFeedback(MedicalDocumentAiFeedback feedback) =>
      di.sl<SubmitMedicalDocumentAiFeedbackUseCase>()(feedback);

  void _dismiss() {
    setState(() => _isDismissed = true);
    widget.onDismissed?.call();
  }
}

class _ThanksFeedback extends StatelessWidget {
  final VoidCallback onDismissed;
  const _ThanksFeedback({required this.onDismissed});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('medical-document-ai-feedback-thanks'),
    padding: const EdgeInsets.all(AppSpacing.m),
    decoration: BoxDecoration(
      gradient: AppColors.aiAnalysisGradient,
      borderRadius: AppBorders.large(),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Gracias por tu respuesta, la tendremos en cuenta para seguir entrenando la IA.',
            style: AppTypography.body6.copyWith(
              color: AppColors.greyNegro,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        IconButton(
          key: const Key('medical-document-ai-feedback-close'),
          onPressed: onDismissed,
          icon: const Icon(Icons.close, color: AppColors.greyIconos, size: 24),
          tooltip: 'Cerrar',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xl,
            minHeight: AppSpacing.xl,
          ),
        ),
      ],
    ),
  );
}

class _FeedbackPrompt extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onDislike;
  final VoidCallback onLike;
  const _FeedbackPrompt({
    required this.isSubmitting,
    required this.onDislike,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.m),
    decoration: BoxDecoration(
      gradient: AppColors.aiAnalysisGradient,
      borderRadius: AppBorders.small(),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '¿La ayuda de la IA te fue útil para leer tu archivo?',
            style: AppTypography.body6.copyWith(
              color: const Color.fromARGB(255, 0, 0, 0),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        _FeedbackButton(
          key: const Key('medical-document-ai-not-useful'),
          icon: Icons.thumb_down_alt,
          onTap: isSubmitting ? null : onDislike,
        ),
        const SizedBox(width: AppSpacing.m),
        _FeedbackButton(
          key: const Key('medical-document-ai-useful'),
          icon: Icons.thumb_up_alt,
          onTap: isSubmitting ? null : onLike,
        ),
      ],
    ),
  );
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _FeedbackButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(AppSpacing.xs),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Ink(
        width: 62,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.primaryFrances),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Center(
          child: Icon(icon, size: 23, color: AppColors.primaryFrances),
        ),
      ),
    ),
  );
}
