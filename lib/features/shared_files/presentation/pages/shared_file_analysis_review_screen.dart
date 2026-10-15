import 'dart:async';

import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_display_formatter.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/analysis_ai_notice.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/analysis_detail_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef SharedFileOriginalUriResolver = Future<Uri> Function();

class SharedFileAnalysisReviewScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onSubmit;
  final VoidCallback? onDoNotUpload;
  final VoidCallback? onViewOriginal;
  final ValueChanged<String?>? onViewOriginalText;
  final VoidCallback? onClose;
  final GlobalKey? closeIconKey;
  final String submitLabel;
  final bool isSubmitting;

  const SharedFileAnalysisReviewScreen({
    super.key,
    required this.analysis,
    this.onSubmit,
    this.onDoNotUpload,
    this.onViewOriginal,
    this.onViewOriginalText,
    this.onClose,
    this.closeIconKey,
    this.submitLabel = 'Subir archivo',
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
      onViewOriginalText: onViewOriginalText,
      onClose: onClose,
      closeIconKey: closeIconKey,
      submitLabel: submitLabel,
      isSubmitting: isSubmitting,
    );
  }
}

class SharedFileSendScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onViewOriginal;
  final ValueChanged<String?>? onViewOriginalText;
  final SharedFileOriginalUriResolver? resolveOriginalUri;
  final String actionLabel;
  final GlobalKey? closeIconKey;
  final GlobalKey? actionIconKey;
  final DateTime? replacementDeadline;
  final bool canReplace;
  final VoidCallback? onContinueEditing;
  final VoidCallback? onDelete;
  final bool isActionLoading;
  final DateTime Function()? now;

  const SharedFileSendScreen({
    super.key,
    required this.analysis,
    this.onViewOriginal,
    this.onViewOriginalText,
    this.resolveOriginalUri,
    this.actionLabel = 'Enviar fórmula',
    this.closeIconKey,
    this.actionIconKey,
    this.replacementDeadline,
    this.canReplace = false,
    this.onContinueEditing,
    this.onDelete,
    this.isActionLoading = false,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    return _SharedFileAnalysisLayout(
      analysis: analysis,
      mode: _SharedFileAnalysisMode.send,
      onViewOriginal: onViewOriginal,
      onViewOriginalText: onViewOriginalText,
      resolveOriginalUri: resolveOriginalUri,
      actionLabel: actionLabel,
      closeIconKey: closeIconKey,
      actionIconKey: actionIconKey,
      replacementDeadline: replacementDeadline,
      canReplace: canReplace,
      onContinueEditing: onContinueEditing,
      onDelete: onDelete,
      isActionLoading: isActionLoading,
      now: now,
    );
  }
}

enum _SharedFileAnalysisMode { review, send }

const _analysisHeaderActionIconSize = 20.0;
const _analysisHeaderActionHeight = 48.0;
const _analysisHeaderTop = AppSpacing.l;
const _analysisNoticeGap = AppSpacing.l;
const _analysisNoticeTopPadding =
    _analysisHeaderTop +
    ((_analysisHeaderActionHeight - _analysisHeaderActionIconSize) / 2) +
    _analysisHeaderActionIconSize +
    _analysisNoticeGap;

class _SharedFileAnalysisLayout extends StatefulWidget {
  final SharedFileAnalysisEntity analysis;
  final _SharedFileAnalysisMode mode;
  final VoidCallback? onSubmit;
  final VoidCallback? onDoNotUpload;
  final VoidCallback? onViewOriginal;
  final ValueChanged<String?>? onViewOriginalText;
  final VoidCallback? onClose;
  final GlobalKey? closeIconKey;
  final GlobalKey? actionIconKey;
  final SharedFileOriginalUriResolver? resolveOriginalUri;
  final String actionLabel;
  final String submitLabel;
  final bool isSubmitting;
  final DateTime? replacementDeadline;
  final bool canReplace;
  final VoidCallback? onContinueEditing;
  final VoidCallback? onDelete;
  final bool isActionLoading;
  final DateTime Function()? now;

  const _SharedFileAnalysisLayout({
    required this.analysis,
    required this.mode,
    this.onSubmit,
    this.onDoNotUpload,
    this.onViewOriginal,
    this.onViewOriginalText,
    this.onClose,
    this.closeIconKey,
    this.actionIconKey,
    this.resolveOriginalUri,
    this.actionLabel = 'Enviar fórmula',
    this.submitLabel = 'Subir archivo',
    this.isSubmitting = false,
    this.replacementDeadline,
    this.canReplace = false,
    this.onContinueEditing,
    this.onDelete,
    this.isActionLoading = false,
    this.now,
  });

  @override
  State<_SharedFileAnalysisLayout> createState() =>
      _SharedFileAnalysisLayoutState();
}

class _SharedFileAnalysisLayoutState extends State<_SharedFileAnalysisLayout> {
  bool _isExporting = false;
  Timer? _expirationTimer;
  late DateTime _currentTime;

  bool get _isSendMode => widget.mode == _SharedFileAnalysisMode.send;

  bool get _hasActiveReplacementWindow {
    final deadline = widget.replacementDeadline;
    return _isSendMode &&
        widget.canReplace &&
        deadline != null &&
        deadline.isAfter(_currentTime);
  }

  int get _remainingSeconds {
    final deadline = widget.replacementDeadline;
    if (deadline == null) return 0;
    final remainingMilliseconds = deadline
        .difference(_currentTime)
        .inMilliseconds;
    if (remainingMilliseconds <= 0) return 0;
    return (remainingMilliseconds + 999) ~/ 1000;
  }

  @override
  void initState() {
    super.initState();
    _currentTime = _readCurrentTime();
    _startExpirationTimer();
  }

  @override
  void didUpdateWidget(covariant _SharedFileAnalysisLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replacementDeadline != widget.replacementDeadline ||
        oldWidget.canReplace != widget.canReplace ||
        oldWidget.mode != widget.mode ||
        oldWidget.now != widget.now) {
      _currentTime = _readCurrentTime();
      _startExpirationTimer();
    }
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveReplacementWindow = _hasActiveReplacementWindow;
    final noticeHeight = _AnalysisNoticeHeader.containerHeightFor(
      context,
      isSendMode: _isSendMode,
    );

    return ModalPageLayout(
      title: '',
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0, height: 0),
      fixedTitle: true,
      fixedHeaderHeight: _AnalysisNoticeHeader.totalHeightFor(
        noticeHeight,
        hasExpiration: hasActiveReplacementWindow,
      ),
      trailingTop: AppSpacing.l,
      trailingRight: AppSpacing.l,
      trailingIcon: IconButton(
        onPressed: widget.onClose ?? () => Navigator.pop(context),
        icon: Icon(
          key: widget.closeIconKey,
          Icons.close,
          size: _analysisHeaderActionIconSize,
          color: AppColors.greyIconos,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      headerChildren: _isSendMode
          ? [
              Positioned(
                top: _analysisHeaderTop,
                left: AppSpacing.l,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isExporting ? null : _exportDocument,
                  child: SizedBox(
                    height: _analysisHeaderActionHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        key: const Key('analysis-header-action-content'),
                        height: _analysisHeaderActionIconSize,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              key: widget.actionIconKey,
                              dimension: _analysisHeaderActionIconSize,
                              child: _isExporting
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : SvgPicture.asset(
                                      AppIcons.export,
                                      width: _analysisHeaderActionIconSize,
                                      height: _analysisHeaderActionIconSize,
                                    ),
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
                ),
              ),
            ]
          : null,
      fixedHeaderChild: _AnalysisNoticeHeader(
        isSendMode: _isSendMode,
        containerHeight: noticeHeight,
        expirationLabel: hasActiveReplacementWindow
            ? _expirationLabel(_remainingSeconds)
            : null,
      ),
      bottomSafeAreaColor: AppColors.white,
      bottomPadding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        0,
      ),
      bottomChild: _isSendMode
          ? _buildSendActions(hasActiveReplacementWindow)
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
          onViewOriginalText: widget.onViewOriginalText,
        ),
      ),
    );
  }

  Widget? _buildSendActions(bool hasActiveReplacementWindow) {
    final showContinueEditing =
        hasActiveReplacementWindow && widget.onContinueEditing != null;
    final showDelete = hasActiveReplacementWindow && widget.onDelete != null;
    if (!showContinueEditing && !showDelete) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showContinueEditing)
          CustomButton(
            key: const Key('analysis-continue-editing-button'),
            text: 'Continuar editando',
            onPressed: widget.onContinueEditing,
            isLoading: widget.isActionLoading,
          ),
        if (showDelete) ...[
          if (showContinueEditing) const SizedBox(height: AppSpacing.m),
          TextButton(
            key: const Key('analysis-delete-file-button'),
            onPressed: widget.isActionLoading ? null : widget.onDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryFrances,
              minimumSize: const Size(double.infinity, 36),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: AppBorders.medium()),
            ),
            child: Text(
              'Eliminar archivo',
              style: AppTypography.body3.copyWith(
                color: AppColors.primaryFrances,
              ),
            ),
          ),
        ],
      ],
    );
  }

  DateTime _readCurrentTime() => widget.now?.call() ?? DateTime.now();

  void _startExpirationTimer() {
    _expirationTimer?.cancel();
    if (!_hasActiveReplacementWindow) return;
    _expirationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateExpiration(),
    );
  }

  void _updateExpiration() {
    if (!mounted) return;
    final currentTime = _readCurrentTime();
    final deadline = widget.replacementDeadline;
    setState(() => _currentTime = currentTime);
    if (deadline == null || !deadline.isAfter(currentTime)) {
      _expirationTimer?.cancel();
      _expirationTimer = null;
    }
  }

  String _expirationLabel(int totalSeconds) {
    final hours = totalSeconds ~/ Duration.secondsPerHour;
    final minutes =
        (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
    final seconds = totalSeconds % Duration.secondsPerMinute;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'Modo edición expira en: '
        '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
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
      final shared = await context.read<SharedFilesCubit>().exportAnalysisPdf(
        exportAnalysis,
      );
      if (shared && mounted) {
        ErrorDisplay.showSuccess(context, 'El archivo se compartió con éxito.');
      }
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
  static const _reviewMinimumContainerHeight = 84.0;
  static const _expirationChipHeight = 24.0;
  static const _expirationNoticeGap = AppSpacing.m;
  static const _reviewMessage =
      'Análisis realizado con IA. Verifica los datos antes de subir el '
      'archivo; una vez enviado, no se admiten cambios ni eliminaciones. Si '
      'seleccionó múltiples animales este será el archivo que se le '
      'asociará a cada uno de ellos.';

  final bool isSendMode;
  final double containerHeight;
  final String? expirationLabel;

  const _AnalysisNoticeHeader({
    required this.isSendMode,
    required this.containerHeight,
    this.expirationLabel,
  });

  static double containerHeightFor(
    BuildContext context, {
    required bool isSendMode,
  }) {
    if (isSendMode) return AnalysisAiNotice.sendHeight;

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

  static double totalHeightFor(
    double containerHeight, {
    bool hasExpiration = false,
  }) =>
      _analysisNoticeTopPadding +
      (hasExpiration ? _expirationChipHeight + _expirationNoticeGap : 0) +
      containerHeight +
      _analysisNoticeGap;

  @override
  Widget build(BuildContext context) {
    final notice = isSendMode
        ? AnalysisAiNotice(
            key: const Key('analysis-ai-notice'),
            height: containerHeight,
          )
        : Container(
            key: const Key('analysis-ai-notice'),
            constraints: BoxConstraints(minHeight: containerHeight),
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
                  child: Text(
                    _reviewMessage,
                    style: AppTypography.body6.copyWith(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        _analysisNoticeTopPadding,
        AppSpacing.l,
        _analysisNoticeGap,
      ),
      child: expirationLabel == null
          ? notice
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(child: _AnalysisExpirationChip(label: expirationLabel!)),
                const SizedBox(height: _expirationNoticeGap),
                notice,
              ],
            ),
    );
  }
}

class _AnalysisExpirationChip extends StatelessWidget {
  final String label;

  const _AnalysisExpirationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('analysis-edit-expiration-chip'),
      height: _AnalysisNoticeHeader._expirationChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.xLarge(),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F1925),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.settings, size: 12, color: AppColors.primaryFrances),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            key: const Key('analysis-edit-expiration-text'),
            style: AppTypography.body5.copyWith(
              color: AppColors.primaryFrances,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisDocumentCard extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;
  final VoidCallback? onViewOriginal;
  final ValueChanged<String?>? onViewOriginalText;

  const _AnalysisDocumentCard({
    required this.analysis,
    this.onViewOriginal,
    this.onViewOriginalText,
  });

  @override
  Widget build(BuildContext context) {
    void viewOriginal(String? text) {
      if (onViewOriginalText != null) {
        onViewOriginalText!(text);
      } else if (onViewOriginal != null) {
        onViewOriginal!();
      } else {
        _showOriginalMessage(context);
      }
    }

    final hasDetailedOriginalLinks =
        analysis.medications.isNotEmpty ||
        analysis.sections.isNotEmpty ||
        (analysis.observations?.trim().isNotEmpty ?? false);
    final showStandaloneOriginalLink =
        analysis.originalFileName.trim().isNotEmpty &&
        !hasDetailedOriginalLinks;
    return Container(
      key: const Key('analysis-document-card'),
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
                  label: analysis.sourceDateLabel?.trim().isNotEmpty == true
                      ? analysis.sourceDateLabel!.trim()
                      : 'Fecha',
                  value: analysis.sourceDateText?.trim().isNotEmpty == true
                      ? analysis.sourceDateText!.trim()
                      : _formatDate(analysis.date!),
                ),
              if ((analysis.date != null ||
                      (analysis.sourceDateText?.trim().isNotEmpty ?? false)) &&
                  analysis.originalFileName.trim().isNotEmpty)
                const SizedBox(height: AppSpacing.xs),
              if (analysis.originalFileName.trim().isNotEmpty)
                _AnalysisValueRow(
                  label:
                      analysis.originalFileNameLabel?.trim().isNotEmpty == true
                      ? analysis.originalFileNameLabel!.trim()
                      : 'Archivo original',
                  value: analysis.originalFileName,
                  valueColor: AppColors.primaryFrances,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  onTap: () => viewOriginal(null),
                ),
              if (showStandaloneOriginalLink) ...[
                const SizedBox(height: AppSpacing.xs),
                _OriginalLink(onTap: () => viewOriginal(null)),
              ],
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
                  style: AppTypography.body6.copyWith(
                    color: AppColors.greyBordes,
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
                  onViewOriginal: () => viewOriginal(
                    _medicationSearchText(analysis.medications[index]),
                  ),
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
              _AnalysisSectionDetails(
                section: analysis.sections[index],
                onViewOriginal: viewOriginal,
                singleOriginalLink:
                    (analysis.documentType.toLowerCase().contains('fórmula') &&
                        _isMedicationSection(analysis.sections[index].title)) ||
                    (analysis.documentType.toLowerCase().contains(
                          'vacunación',
                        ) &&
                        _isVaccinationSection(
                          analysis.sections[index].title,
                        )) ||
                    _isLaboratoryResultDocument(analysis.documentType),
              ),
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
                medicalDocumentNarrativeDisplayValue(analysis.observations!),
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _OriginalLink(onTap: () => viewOriginal(analysis.observations)),
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
              style: AppTypography.body5.copyWith(color: AppColors.greyTextos),
              children: [
                const TextSpan(text: 'Paciente '),
                TextSpan(
                  text: patient.name,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.primaryAzulClaro,
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
              style: AppTypography.body5.copyWith(color: AppColors.greyTextos),
              children: [
                const TextSpan(text: 'Tutor '),
                TextSpan(
                  text: tutor.name,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.primaryAzulClaro,
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
              style: AppTypography.body5.copyWith(color: AppColors.greyTextos),
              children: [
                const TextSpan(text: 'Veterinario '),
                TextSpan(
                  text: veterinarian.name,
                  style: AppTypography.body5.copyWith(
                    color: AppColors.primaryAzulClaro,
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
  final VoidCallback? onTap;

  const _AnalysisValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines,
    this.overflow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 119, child: AnalysisDetailLabel(label: label)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(
              value,
              maxLines: maxLines,
              overflow: overflow,
              style: AppTypography.body4.copyWith(
                color: valueColor ?? AppColors.greyTextos,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisSectionDetails extends StatelessWidget {
  final SharedFileAnalysisSectionEntity section;
  final ValueChanged<String?> onViewOriginal;
  final bool singleOriginalLink;

  const _AnalysisSectionDetails({
    required this.section,
    required this.onViewOriginal,
    this.singleOriginalLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = section.details
        .where((detail) => detail.hasData)
        .toList(growable: false);
    final body = section.body?.trim() ?? '';
    final isGeneralInformation =
        section.title.trim().toLowerCase() == 'información general';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
        ),
        if (body.isNotEmpty || details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        if (body.isNotEmpty) ...[
          Text(
            medicalDocumentNarrativeDisplayValue(body),
            style: AppTypography.body4.copyWith(
              color: AppColors.greyTextos,
              height: 1.55,
            ),
          ),
          if (!singleOriginalLink) ...[
            const SizedBox(height: AppSpacing.xs),
            _OriginalLink(onTap: () => onViewOriginal(body)),
          ],
        ],
        if (body.isNotEmpty && details.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < details.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _AnalysisValueRow(
            label: details[index].label,
            value: details[index].value,
          ),
          if (!singleOriginalLink &&
              !(isGeneralInformation &&
                  details[index].label.trim().toLowerCase() ==
                      'tipo de documento')) ...[
            const SizedBox(height: AppSpacing.xs),
            _OriginalLink(onTap: () => onViewOriginal(details[index].value)),
          ],
        ],
        if (singleOriginalLink && (body.isNotEmpty || details.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.xs),
          _OriginalLink(
            onTap: () =>
                onViewOriginal(_sectionSearchText(section, details, body)),
          ),
        ],
      ],
    );
  }
}

bool _isMedicationSection(String title) =>
    RegExp(r'^medicamentos?\b', caseSensitive: false).hasMatch(title.trim());

bool _isVaccinationSection(String title) =>
    RegExp(r'^vacunas?\b', caseSensitive: false).hasMatch(title.trim());

bool _isLaboratoryResultDocument(String documentType) =>
    documentType.trim().toLowerCase().contains('laboratorio');

String _sectionSearchText(
  SharedFileAnalysisSectionEntity section,
  List<SharedFileAnalysisDetailEntity> details,
  String body,
) {
  if (!_isVaccinationSection(section.title)) {
    return _searchTextFromParts([
      for (final detail in details) detail.value,
      body,
    ]);
  }
  final vaccineIndex = details.indexWhere(
    (detail) => detail.label.trim().toLowerCase() == 'vacuna',
  );
  final dateIndex = details.indexWhere(
    (detail) => detail.label.trim().toLowerCase().startsWith('fecha de apli'),
  );
  return _searchTextFromParts([
    if (vaccineIndex >= 0) details[vaccineIndex].value,
    if (dateIndex >= 0) details[dateIndex].value,
    for (var index = 0; index < details.length; index++)
      if (index != vaccineIndex && index != dateIndex) details[index].value,
    body,
  ]);
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
                    medicalDocumentNarrativeDisplayValue(medication.name),
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
              medicalDocumentNarrativeDisplayValue(medication.instructions),
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
          style: AppTypography.body6.copyWith(color: AppColors.primaryFrances),
        ),
      ),
    );
  }
}

String _medicationSearchText(SharedFileMedicationAnalysisEntity medication) =>
    _searchTextFromParts([
      medication.name,
      if (medication.quantity != null) medication.quantity.toString(),
      medication.instructions,
      for (final detail in medication.details)
        if (detail.hasData) detail.value,
    ]);

String _searchTextFromParts(Iterable<String> parts) => parts
    .map((part) => part.trim())
    .where((part) => part.isNotEmpty)
    .join('\n');
