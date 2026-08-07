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

class SharedFileAnalysisReviewScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;

  const SharedFileAnalysisReviewScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return _SharedFileAnalysisLayout(
      analysis: analysis,
      mode: _SharedFileAnalysisMode.review,
    );
  }
}

class SharedFileSendScreen extends StatelessWidget {
  final SharedFileAnalysisEntity analysis;

  const SharedFileSendScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return _SharedFileAnalysisLayout(
      analysis: analysis,
      mode: _SharedFileAnalysisMode.send,
    );
  }
}

enum _SharedFileAnalysisMode { review, send }

class _SharedFileAnalysisLayout extends StatefulWidget {
  final SharedFileAnalysisEntity analysis;
  final _SharedFileAnalysisMode mode;

  const _SharedFileAnalysisLayout({required this.analysis, required this.mode});

  @override
  State<_SharedFileAnalysisLayout> createState() =>
      _SharedFileAnalysisLayoutState();
}

class _SharedFileAnalysisLayoutState extends State<_SharedFileAnalysisLayout> {
  bool _isExporting = false;

  bool get _isSendMode => widget.mode == _SharedFileAnalysisMode.send;

  @override
  Widget build(BuildContext context) {
    return ModalPageLayout(
      title: '',
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0, height: 0),
      fixedTitle: true,
      fixedHeaderHeight: _isSendMode ? 164 : 180,
      trailingTop: AppSpacing.l,
      trailingRight: AppSpacing.l,
      trailingIcon: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, color: AppColors.greyIconos),
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
                  onTap: _isExporting ? null : _exportFormula,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isExporting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        SvgPicture.asset(
                          AppIcons.export,
                          width: 20,
                          height: 20,
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Enviar fórmula',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          : null,
      fixedHeaderChild: _AnalysisNoticeHeader(isSendMode: _isSendMode),
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
          : CustomButton(text: 'Subir documento', onPressed: _openSendScreen),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: _AnalysisDocumentCard(
          analysis: widget.analysis,
          showTutor: _isSendMode,
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

  Future<void> _exportFormula() async {
    setState(() => _isExporting = true);
    try {
      await context.read<SharedFilesCubit>().exportAnalysisPdf(widget.analysis);
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
  final bool isSendMode;

  const _AnalysisNoticeHeader({required this.isSendMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        72,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Container(
        height: isSendMode ? 68 : 84,
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
                      'Análisis realizado con IA. Verifica los datos antes de '
                      'subir el archivo; una vez enviado, no se admiten cambios '
                      'ni eliminaciones.',
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
  final bool showTutor;

  const _AnalysisDocumentCard({
    required this.analysis,
    required this.showTutor,
  });

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: AppSpacing.xl),
            _AnalysisValueRow(
              label: 'Fecha',
              value: _formatDate(analysis.date),
            ),
            const SizedBox(height: AppSpacing.xs),
            _AnalysisValueRow(
              label: 'Archivo original',
              value: analysis.originalFileName,
              valueColor: AppColors.primaryFrances,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.l),
            const Divider(height: 1, color: AppColors.greyDelineante),
            const SizedBox(height: AppSpacing.l),
            _PatientDetails(patient: analysis.patient),
            if (showTutor) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
              const SizedBox(height: AppSpacing.l),
              _TutorDetails(tutor: analysis.tutor),
            ],
            if (analysis.medications.isNotEmpty ||
                (analysis.observations?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: AppSpacing.l),
              const Divider(height: 1, color: AppColors.greyDelineante),
            ],
            if (analysis.medications.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.l),
              for (
                var index = 0;
                index < analysis.medications.length;
                index++
              ) ...[
                _MedicationDetails(
                  medication: analysis.medications[index],
                  onViewOriginal: () => _showOriginalMessage(context),
                ),
                if (index < analysis.medications.length - 1)
                  const SizedBox(height: AppSpacing.l),
              ],
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
          const SizedBox(height: 6),
          Text(
            analysis.documentNumber,
            style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: AppSpacing.m),
        _AnalysisValueRow(label: 'Animal Record ID', value: patient.recordId),
        const SizedBox(height: AppSpacing.xs),
        _AnalysisValueRow(label: 'Especie', value: patient.species),
        const SizedBox(height: AppSpacing.xs),
        _AnalysisValueRow(label: 'Raza', value: patient.breed),
        const SizedBox(height: AppSpacing.xs),
        _AnalysisValueRow(label: 'Edad', value: patient.age),
        const SizedBox(height: AppSpacing.xs),
        _AnalysisValueRow(label: 'Peso', value: patient.weight),
      ],
    );
  }
}

class _TutorDetails extends StatelessWidget {
  final SharedFileTutorAnalysisEntity tutor;

  const _TutorDetails({required this.tutor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: AppSpacing.m),
        _AnalysisValueRow(label: 'Identificación', value: tutor.identification),
        const SizedBox(height: AppSpacing.xs),
        _AnalysisValueRow(label: 'Número celular', value: tutor.phoneNumber),
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
            Expanded(
              child: Text(
                medication.name,
                style: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'x ${medication.quantity}',
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
            ),
          ],
        ),
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
        if (medication.originalUrl?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onViewOriginal,
              child: Text(
                'Ver original',
                style: AppTypography.body4.copyWith(
                  color: AppColors.primaryFrances,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
