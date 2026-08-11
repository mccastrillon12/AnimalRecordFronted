import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef SharedFileOriginalUriResolver = Future<Uri> Function();

class SharedFileAnalysisReviewScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onSubmit;
  final VoidCallback? onDoNotUpload;
  final VoidCallback? onViewOriginal;
  final VoidCallback? onClose;
  final String submitLabel;
  final bool isSubmitting;

  const SharedFileAnalysisReviewScreen({
    super.key,
    required this.analysis,
    this.onSubmit,
    this.onDoNotUpload,
    this.onViewOriginal,
    this.onClose,
    this.submitLabel = 'Subir documento',
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SharedFileAnalysisLayout(
      analysis: analysis,
      mode: _SharedFileAnalysisMode.review,
      onSubmit: onSubmit,
      onDoNotUpload: onDoNotUpload,
      onViewOriginal: onViewOriginal,
      onClose: onClose,
      submitLabel: submitLabel,
      isSubmitting: isSubmitting,
    );
  }
}

class SharedFileSendScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onViewOriginal;
  final SharedFileOriginalUriResolver? resolveOriginalUri;
  final String actionLabel;

  const SharedFileSendScreen({
    super.key,
    required this.analysis,
    this.onViewOriginal,
    this.resolveOriginalUri,
    this.actionLabel = 'Enviar fórmula',
  });

  @override
  Widget build(BuildContext context) {
    return _SharedFileAnalysisLayout(
      analysis: analysis,
      mode: _SharedFileAnalysisMode.send,
      onViewOriginal: onViewOriginal,
      resolveOriginalUri: resolveOriginalUri,
      actionLabel: actionLabel,
    );
  }
}

enum _SharedFileAnalysisMode { review, send }

class _SharedFileAnalysisLayout extends StatefulWidget {
  final SharedFileAnalysisEntity analysis;
  final _SharedFileAnalysisMode mode;
  final VoidCallback? onSubmit;
  final VoidCallback? onDoNotUpload;
  final VoidCallback? onViewOriginal;
  final VoidCallback? onClose;
  final SharedFileOriginalUriResolver? resolveOriginalUri;
  final String actionLabel;
  final String submitLabel;
  final bool isSubmitting;

  const _SharedFileAnalysisLayout({
    required this.analysis,
    required this.mode,
    this.onSubmit,
    this.onDoNotUpload,
    this.onViewOriginal,
    this.onClose,
    this.resolveOriginalUri,
    this.actionLabel = 'Enviar fórmula',
    this.submitLabel = 'Subir documento',
    this.isSubmitting = false,
  });

  @override
  State<_SharedFileAnalysisLayout> createState() =>
      _SharedFileAnalysisLayoutState();
}

class _SharedFileAnalysisLayoutState extends State<_SharedFileAnalysisLayout> {
  static const _headerActionIconSize = 20.0;
  static const _headerActionHeight = 48.0;

  bool _isExporting = false;

  bool get _isSendMode => widget.mode == _SharedFileAnalysisMode.send;

  @override
  Widget build(BuildContext context) {
    final noticeHeight = _AnalysisNoticeHeader.containerHeightFor(
      context,
      isSendMode: _isSendMode,
    );

    return ModalPageLayout(
      title: '',
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0, height: 0),
      fixedTitle: true,
      fixedHeaderHeight: _AnalysisNoticeHeader.totalHeightFor(noticeHeight),
      trailingTop: AppSpacing.l,
      trailingRight: AppSpacing.l,
      trailingIcon: IconButton(
        onPressed: widget.onClose ?? () => Navigator.pop(context),
        icon: const Icon(
          Icons.close,
          size: _headerActionIconSize,
          color: AppColors.greyIconos,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      headerChildren: _isSendMode
          ? [
              Positioned(
                top: AppSpacing.l,
                left: AppSpacing.l,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isExporting ? null : _exportDocument,
                  child: SizedBox(
                    height: _headerActionHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isExporting)
                          const SizedBox(
                            width: _headerActionIconSize,
                            height: _headerActionIconSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          SvgPicture.asset(
                            AppIcons.export,
                            width: _headerActionIconSize,
                            height: _headerActionIconSize,
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          widget.actionLabel,
                          style: AppTypography.body4.copyWith(
                            color: AppColors.greyMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
          : null,
      fixedHeaderChild: _AnalysisNoticeHeader(
        isSendMode: _isSendMode,
        containerHeight: noticeHeight,
      ),
      bottomSafeAreaColor: AppColors.white,
      bottomPadding: _isSendMode
          ? null
          : const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              0,
            ),
      bottomChild: _isSendMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButton(
                  text: widget.isSubmitting
                      ? 'Guardando...'
                      : widget.submitLabel,
                  onPressed: widget.isSubmitting
                      ? null
                      : widget.onSubmit ?? _openSendScreen,
                ),
                if (widget.onDoNotUpload != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton(
                    onPressed: widget.isSubmitting
                        ? null
                        : widget.onDoNotUpload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryFrances,
                      disabledForegroundColor: AppColors.greyMedio,
                      minimumSize: const Size(double.infinity, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: widget.isSubmitting
                            ? AppColors.greyDelineante
                            : AppColors.primaryFrances,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorders.medium(),
                      ),
                    ),
                    child: Text(
                      'No subir',
                      style: AppTypography.body3.copyWith(
                        color: widget.isSubmitting
                            ? AppColors.greyMedio
                            : AppColors.primaryFrances,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: _AnalysisDocumentCard(
          analysis: widget.analysis,
          onViewOriginal: widget.onViewOriginal,
        ),
      ),
    );
  }

  void _openSendScreen() {
    Navigator.pushNamed(
      context,
      AppRoutes.sharedFileSend,
      arguments: widget.analysis,
    );
  }

  Future<void> _exportDocument() async {
    setState(() => _isExporting = true);
    try {
      var exportAnalysis = widget.analysis;
      if (widget.resolveOriginalUri case final resolveOriginalUri?) {
        final originalUri = await resolveOriginalUri();
        exportAnalysis = exportAnalysis.withOriginalUrl(originalUri.toString());
      }
      if (!mounted) return;
      await context.read<SharedFilesCubit>().exportAnalysisPdf(exportAnalysis);
    } catch (_) {
      if (mounted) {
        ErrorDisplay.showError(
          context,
          'No fue posible generar el PDF. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _AnalysisNoticeHeader extends StatelessWidget {
  static const _topPadding = 72.0;
  static const _sendContainerHeight = 68.0;
  static const _reviewMinimumContainerHeight = 84.0;
  static const _reviewMessage =
      'Análisis realizado con IA. Verifica los datos antes de subir el '
      'archivo; una vez enviado, no se admiten cambios ni eliminaciones. Si '
      'seleccionó múltiples animales este será el documento que se le '
      'asociará a cada uno de ellos.';

  final bool isSendMode;
  final double containerHeight;

  const _AnalysisNoticeHeader({
    required this.isSendMode,
    required this.containerHeight,
  });

  static double containerHeightFor(
    BuildContext context, {
    required bool isSendMode,
  }) {
    if (isSendMode) return _sendContainerHeight;

    final availableTextWidth =
        (MediaQuery.sizeOf(context).width -
                (AppSpacing.l * 2) -
                (AppSpacing.m * 2) -
                12 -
                AppSpacing.s)
            .clamp(1.0, double.infinity)
            .toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: _reviewMessage,
        style: AppTypography.body6.copyWith(
          color: AppColors.greyNegro,
          height: 1.4,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: availableTextWidth);
    final requiredHeight = painter.height + (AppSpacing.m * 2);
    return requiredHeight > _reviewMinimumContainerHeight
        ? requiredHeight
        : _reviewMinimumContainerHeight;
  }

  static double totalHeightFor(double containerHeight) =>
      _topPadding + containerHeight + AppSpacing.l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        _topPadding,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Container(
        height: containerHeight,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: AppColors.aiAnalysisGradient,
          borderRadius: AppBorders.small(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: SvgPicture.asset(
                AppIcons.magicStar,
                width: 12,
                height: 12,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: isSendMode
                  ? RichText(
                      text: TextSpan(
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyNegro,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Análisis realizado con IA. '),
                          TextSpan(
                            text:
                                'Verifica siempre los datos con el archivo original.',
                            style: AppTypography.body6.copyWith(
                              color: AppColors.greyNegro,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      _reviewMessage,
                      style: AppTypography.body6.copyWith(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        height: 1.4,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisDocumentCard extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onViewOriginal;

  const _AnalysisDocumentCard({required this.analysis, this.onViewOriginal});

  @override
  Widget build(BuildContext context) {
    final viewOriginal = onViewOriginal ?? () => _showOriginalMessage(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.large(),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.xl,
          AppSpacing.m,
          AppSpacing.l,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppBorders.medium(),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyNegro.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DocumentHeader(analysis: analysis),
            if (analysis.date != null ||
                (analysis.sourceDateText?.trim().isNotEmpty ?? false) ||
                analysis.originalFileName.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              if (analysis.date != null ||
                  (analysis.sourceDateText?.trim().isNotEmpty ?? false))
                _AnalysisValueRow(
                  label: 'Fecha',
                  value: analysis.date != null
                      ? _formatDate(analysis.date!)
                      : analysis.sourceDateText!.trim(),
                ),
              if ((analysis.date != null ||
                      (analysis.sourceDateText?.trim().isNotEmpty ?? false)) &&
                  analysis.originalFileName.trim().isNotEmpty)
                const SizedBox(height: AppSpacing.xs),
              if (analysis.originalFileName.trim().isNotEmpty)
                _AnalysisValueRow(
                  label: 'Archivo original',
                  value: analysis.originalFileName,
                  valueColor: AppColors.primaryFrances,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            if (analysis.patient.hasData) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
              const SizedBox(height: AppSpacing.l),
              _PatientDetails(patient: analysis.patient),
            ],
            if (analysis.veterinarian?.hasData ?? false) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
              const SizedBox(height: AppSpacing.l),
              _VeterinarianDetails(veterinarian: analysis.veterinarian!),
            ],
            if (analysis.tutor.hasData) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
              const SizedBox(height: AppSpacing.l),
              _TutorDetails(tutor: analysis.tutor),
            ],
            if (analysis.medications.isNotEmpty ||
                analysis.sections.isNotEmpty ||
                (analysis.observations?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
            ],
            if (analysis.medications.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.l),
              if (analysis.itemsTitle?.trim().isNotEmpty ?? false) ...[
                Text(
                  analysis.itemsTitle!,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              for (
                var index = 0;
                index < analysis.medications.length;
                index++
              ) ...[
                _MedicationDetails(
                  medication: analysis.medications[index],
                  onViewOriginal: viewOriginal,
                ),
                if (index < analysis.medications.length - 1)
                  const SizedBox(height: AppSpacing.l),
              ],
            ],
            for (var index = 0; index < analysis.sections.length; index++) ...[
              SizedBox(
                height: analysis.medications.isNotEmpty || index > 0
                    ? AppSpacing.xl
                    : AppSpacing.l,
              ),
              _AnalysisSectionDetails(section: analysis.sections[index]),
              const SizedBox(height: AppSpacing.xs),
              _OriginalLink(onTap: viewOriginal),
            ],
            if (analysis.observations?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Observaciones',
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyBordes,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                analysis.observations!,
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _OriginalLink(onTap: viewOriginal),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showOriginalMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La vista del archivo original estará disponible próximamente.',
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;

  const _DocumentHeader({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SvgPicture.asset(
            AppIcons.clipboardImport,
            width: AppSpacing.iconSizeSmall,
            height: AppSpacing.iconSizeSmall,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryAzulClaro,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.documentType,
            textAlign: TextAlign.center,
            style: AppTypography.body3.copyWith(color: AppColors.greyTextos),
          ),
          if (analysis.documentNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              analysis.documentNumber,
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientDetails extends StatelessWidget {
  final SharedFilePatientAnalysisEntity patient;

  const _PatientDetails({required this.patient});

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      if (patient.recordId.trim().isNotEmpty)
        (label: 'Animal Record ID', value: patient.recordId),
      if (patient.species.trim().isNotEmpty)
        (label: 'Especie', value: patient.species),
      if (patient.breed.trim().isNotEmpty)
        (label: 'Raza', value: patient.breed),
      if (patient.sex.trim().isNotEmpty) (label: 'Sexo', value: patient.sex),
      if (patient.color.trim().isNotEmpty)
        (label: 'Color', value: patient.color),
      if (patient.age.trim().isNotEmpty) (label: 'Edad', value: patient.age),
      if (patient.weight.trim().isNotEmpty)
        (label: 'Peso', value: patient.weight),
      for (final detail in patient.additionalDetails)
        if (detail.hasData) (label: detail.label, value: detail.value),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (patient.name.trim().isNotEmpty)
          RichText(
            text: TextSpan(
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Paciente '),
                TextSpan(
                  text: patient.name,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.primaryAzulClaro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (patient.name.trim().isNotEmpty && details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _AnalysisValueRow(
            label: details[index].label,
            value: details[index].value,
          ),
        ],
      ],
    );
  }
}

class _TutorDetails extends StatelessWidget {
  final SharedFileTutorAnalysisEntity tutor;

  const _TutorDetails({required this.tutor});

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      if (tutor.identification.trim().isNotEmpty)
        (label: 'Identificación', value: tutor.identification),
      if (tutor.phoneNumber.trim().isNotEmpty)
        (label: 'Número celular', value: tutor.phoneNumber),
      for (final detail in tutor.additionalDetails)
        if (detail.hasData) (label: detail.label, value: detail.value),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tutor.name.trim().isNotEmpty)
          RichText(
            text: TextSpan(
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Tutor '),
                TextSpan(
                  text: tutor.name,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.primaryAzulClaro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (tutor.name.trim().isNotEmpty && details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _AnalysisValueRow(
            label: details[index].label,
            value: details[index].value,
          ),
        ],
      ],
    );
  }
}

class _VeterinarianDetails extends StatelessWidget {
  final SharedFileVeterinarianAnalysisEntity veterinarian;

  const _VeterinarianDetails({required this.veterinarian});

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      if (veterinarian.clinic.trim().isNotEmpty)
        (label: 'Clínica', value: veterinarian.clinic),
      if (veterinarian.professionalId.trim().isNotEmpty)
        (label: 'Registro profesional', value: veterinarian.professionalId),
      for (final detail in veterinarian.additionalDetails)
        if (detail.hasData) (label: detail.label, value: detail.value),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (veterinarian.name.trim().isNotEmpty)
          RichText(
            text: TextSpan(
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.bold,
              ),
              children: [
                const TextSpan(text: 'Veterinario '),
                TextSpan(
                  text: veterinarian.name,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.primaryAzulClaro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (veterinarian.name.trim().isNotEmpty && details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _AnalysisValueRow(
            label: details[index].label,
            value: details[index].value,
          ),
        ],
      ],
    );
  }
}

class _AnalysisValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final int? maxLines;
  final TextOverflow? overflow;

  const _AnalysisValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 119,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: overflow,
            style: AppTypography.body4.copyWith(
              color: valueColor ?? AppColors.greyTextos,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisSectionDetails extends StatelessWidget {
  final SharedFileAnalysisSectionEntity section;

  const _AnalysisSectionDetails({required this.section});

  @override
  Widget build(BuildContext context) {
    final details = section.details
        .where((detail) => detail.hasData)
        .toList(growable: false);
    final body = section.body?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body3.copyWith(color: AppColors.greyTextos),
        ),
        if (body.isNotEmpty || details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        if (body.isNotEmpty)
          Text(
            body,
            style: AppTypography.body4.copyWith(
              color: AppColors.greyTextos,
              height: 1.55,
            ),
          ),
        if (body.isNotEmpty && details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _AnalysisValueRow(
            label: details[index].label,
            value: details[index].value,
          ),
        ],
      ],
    );
  }
}

class _MedicationDetails extends StatelessWidget {
  final SharedFileMedicationAnalysisEntity medication;
  final VoidCallback onViewOriginal;

  const _MedicationDetails({
    required this.medication,
    required this.onViewOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (medication.name.trim().isNotEmpty || medication.quantity != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primaryAzulClaro,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (medication.name.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    medication.name,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyTextos,
                      height: 1.5,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (medication.quantity != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'x ${medication.quantity}',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
              ],
            ],
          ),
        if (medication.instructions.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: AppSpacing.xs),
            child: Text(
              medication.instructions,
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                height: 1.55,
              ),
            ),
          ),
        if (medication.details.any((detail) => detail.hasData))
          Padding(
            padding: const EdgeInsets.only(left: 22, top: AppSpacing.xs),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < medication.details.length;
                  index++
                ) ...[
                  if (medication.details[index].hasData) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.xs),
                    _AnalysisValueRow(
                      label: medication.details[index].label,
                      value: medication.details[index].value,
                    ),
                  ],
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        _OriginalLink(onTap: onViewOriginal),
      ],
    );
  }
}

class _OriginalLink extends StatelessWidget {
  final VoidCallback onTap;

  const _OriginalLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          'Ver original',
          style: AppTypography.body4.copyWith(color: AppColors.primaryFrances),
        ),
      ),
    );
  }
}
