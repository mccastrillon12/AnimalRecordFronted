import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_rejection_reason.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<MedicalDocumentRejectionSelection?> showMedicalDocumentRejectionDialog({
  required BuildContext context,
  required Future<List<MedicalDocumentRejectionReasonEntity>> Function()
  loadReasons,
  Future<void> Function()? onCancel,
}) async {
  MedicalDocumentRejectionSelection? confirmedSelection;
  var cancellationRequested = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _MedicalDocumentRejectionDialog(
      loadReasons: loadReasons,
      onConfirm: (selection) => confirmedSelection = selection,
      onCancel: () => cancellationRequested = true,
    ),
  );

  if (cancellationRequested) await onCancel?.call();
  return confirmedSelection;
}

class _MedicalDocumentRejectionDialog extends StatefulWidget {
  final Future<List<MedicalDocumentRejectionReasonEntity>> Function()
  loadReasons;
  final ValueChanged<MedicalDocumentRejectionSelection> onConfirm;
  final VoidCallback onCancel;

  const _MedicalDocumentRejectionDialog({
    required this.loadReasons,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_MedicalDocumentRejectionDialog> createState() =>
      _MedicalDocumentRejectionDialogState();
}

class _MedicalDocumentRejectionDialogState
    extends State<_MedicalDocumentRejectionDialog> {
  final _commentController = TextEditingController();
  List<MedicalDocumentRejectionReasonEntity>? _reasons;
  MedicalDocumentRejectionReasonEntity? _selectedReason;
  String? _loadError;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_refresh);
    _loadReasons();
  }

  @override
  void dispose() {
    _commentController.removeListener(_refresh);
    _commentController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final reasons = await widget.loadReasons();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _isLoading = false;
        if (reasons.isEmpty) {
          _loadError = 'No hay motivos de rechazo disponibles.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'No fue posible cargar los motivos de rechazo.';
      });
    }
  }

  bool get _canConfirm {
    final reason = _selectedReason;
    if (reason == null || _isLoading || _loadError != null) return false;
    return !reason.requiresComment || _commentController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDialog(
      title: '¿Qué estuvo mal?',
      titleColor: AppColors.aiViolet,
      headerLeading: const _AiIndicator(),
      description:
          'Selecciona el motivo por el cual no desea subir el archivo. '
          'Si fue error de lectura podrá reintentarlo.',
      content: _buildContent(),
      confirmLabel: 'Reintentar',
      confirmColor: AppColors.aiViolet,
      isConfirmEnabled: _canConfirm,
      onConfirm: () {
        final reason = _selectedReason;
        if (reason == null) return;
        final comment = _commentController.text.trim();
        widget.onConfirm(
          MedicalDocumentRejectionSelection(
            reason: reason,
            comment: comment.isEmpty ? null : comment,
          ),
        );
      },
      onCancel: widget.onCancel,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        key: Key('rejection-reasons-loading'),
        height: 64,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.aiViolet),
        ),
      );
    }
    if (_loadError case final error?) {
      return Column(
        key: const Key('rejection-reasons-error'),
        children: [
          Text(
            error,
            style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _loadReasons, child: const Text('Reintentar')),
        ],
      );
    }

    final reason = _selectedReason;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDropdown<MedicalDocumentRejectionReasonEntity>(
          label: 'Seleccionar el motivo:',
          hint: 'Motivo',
          value: reason,
          items: _reasons ?? const [],
          itemAsString: (item) => item.label,
          preserveOrder: true,
          showClearOption: false,
          isInline: true,
          pushContent: true,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
              if (value?.requiresComment != true) {
                _commentController.clear();
              }
            });
          },
        ),
        if (reason?.requiresComment == true) ...[
          const SizedBox(height: AppSpacing.s),
          CustomTextField(
            key: const Key('rejection-reason-comment'),
            label: 'Describe el motivo:',
            hint: 'Comentario',
            controller: _commentController,
            maxLength: 250,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }
}

class _AiIndicator extends StatelessWidget {
  const _AiIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppIcons.magicStar, width: 18, height: 18),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          'IA',
          style: AppTypography.body6.copyWith(color: AppColors.aiViolet),
        ),
      ],
    );
  }
}
