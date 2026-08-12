import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VaccinationGroupDetailScreen extends StatefulWidget {
  final VaccinationGroupViewData group;
  final VoidCallback onSend;

  const VaccinationGroupDetailScreen({
    super.key,
    required this.group,
    required this.onSend,
  });

  @override
  State<VaccinationGroupDetailScreen> createState() =>
      _VaccinationGroupDetailScreenState();
}

class _VaccinationGroupDetailScreenState
    extends State<VaccinationGroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detail = vaccinationDetailViewData(widget.group);
    return ModalPageLayout(
      title: '',
      titlePadding: EdgeInsets.zero,
      titleStyle: const TextStyle(fontSize: 0, height: 0),
      fixedTitle: true,
      fixedHeaderHeight: 76,
      trailingTop: AppSpacing.l,
      trailingRight: AppSpacing.l,
      trailingIcon: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close, size: 20, color: AppColors.greyIconos),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      headerChildren: [
        Positioned(
          top: AppSpacing.l,
          left: AppSpacing.l,
          child: GestureDetector(
            key: const Key('export-vaccination-group'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSend,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(AppIcons.export, width: 20, height: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Enviar',
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyMedio,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      bottomSafeAreaColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.xl,
        ),
        child: VaccinationRecordList(
          detail: detail,
          onViewOriginal: _showOriginal,
        ),
      ),
    );
  }

  Future<void> _showOriginal(MedicalDocumentEntity document) async {
    final preview = MedicalDocumentOriginalPreview(
      getDownloadUriUseCase: di.sl<GetMedicalDocumentDownloadUriUseCase>(),
      saveOriginalUseCase: di.sl<SaveMedicalDocumentOriginalUseCase>(),
    );
    try {
      await preview.show(
        context,
        acceptedDocumentId: document.id,
        fileName: document.originalFileName,
        mimeType: document.mimeType,
      );
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class VaccinationRecordList extends StatelessWidget {
  final VaccinationDetailViewData detail;
  final ValueChanged<MedicalDocumentEntity> onViewOriginal;
  final double recordSpacing;
  final bool groupDoses;

  const VaccinationRecordList({
    super.key,
    required this.detail,
    required this.onViewOriginal,
    this.recordSpacing = AppSpacing.xl,
    this.groupDoses = false,
  });

  @override
  Widget build(BuildContext context) {
    if (groupDoses) {
      return _GroupedVaccinationRecordBlock(
        key: Key('vaccination-type-${detail.vaccineName.toLowerCase()}'),
        detail: detail,
        onViewOriginal: onViewOriginal,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < detail.doses.length; index++) ...[
            _VaccinationRecordBlock(
              key: Key(
                'vaccination-record-${detail.doses[index].document.id}-$index',
              ),
              vaccineName: detail.vaccineName,
              dose: detail.doses[index],
              onViewOriginal: () =>
                  onViewOriginal(detail.doses[index].document),
            ),
            if (index < detail.doses.length - 1)
              SizedBox(height: recordSpacing),
          ],
        ],
      ),
    );
  }
}

class _GroupedVaccinationRecordBlock extends StatelessWidget {
  final VaccinationDetailViewData detail;
  final ValueChanged<MedicalDocumentEntity> onViewOriginal;

  const _GroupedVaccinationRecordBlock({
    super.key,
    required this.detail,
    required this.onViewOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.large(),
      ),
      child: _VaccinationSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < detail.doses.length; index++) ...[
              _DoseSection(
                vaccineName: detail.vaccineName,
                dose: detail.doses[index],
                showHeader: index == 0,
                headerTitle: 'Vacuna',
                onViewOriginal: () =>
                    onViewOriginal(detail.doses[index].document),
              ),
              if (index < detail.doses.length - 1) ...[
                const SizedBox(height: AppSpacing.l),
                const Divider(height: 1, color: AppColors.greyDelineante),
                const SizedBox(height: AppSpacing.l),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _VaccinationRecordBlock extends StatelessWidget {
  final String vaccineName;
  final VaccinationDoseViewData dose;
  final VoidCallback onViewOriginal;

  const _VaccinationRecordBlock({
    super.key,
    required this.vaccineName,
    required this.dose,
    required this.onViewOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.large(),
      ),
      child: _VaccinationSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoseSection(
              vaccineName: vaccineName,
              dose: dose,
              onViewOriginal: onViewOriginal,
            ),
            if (dose.tutor.hasData) ...[
              const SizedBox(height: AppSpacing.xl),
              _TutorSection(tutor: dose.tutor),
            ],
            if (dose.patient.hasData) ...[
              const SizedBox(height: AppSpacing.xl),
              _PatientSection(patient: dose.patient),
            ],
          ],
        ),
      ),
    );
  }
}

class _VaccinationSectionCard extends StatelessWidget {
  final Widget child;

  const _VaccinationSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.medium(),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DoseSection extends StatelessWidget {
  final String vaccineName;
  final VaccinationDoseViewData dose;
  final VoidCallback onViewOriginal;
  final bool showHeader;
  final String headerTitle;

  const _DoseSection({
    required this.vaccineName,
    required this.dose,
    required this.onViewOriginal,
    this.showHeader = true,
    this.headerTitle = 'Detalle de vacunación',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Center(
            child: Column(
              children: [
                SvgPicture.asset(AppIcons.vaccineShield, width: 17, height: 21),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  headerTitle,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vaccineName,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
              ],
            ),
          ),
          if (dose.nextDoseDate.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _DetailValue(
              label: dose.nextDoseDateLabel,
              value: dose.nextDoseDate,
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          const Divider(height: 1, color: AppColors.greyDelineante),
          const SizedBox(height: AppSpacing.l),
        ],
        Text(
          dose.title,
          style: AppTypography.body3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (dose.details.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          for (var index = 0; index < dose.details.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            _DetailValue(
              label: dose.details[index].label,
              value: dose.details[index].value,
              showImage: dose.details[index].label == 'Etiqueta',
            ),
          ],
        ],
        if (dose.veterinarian?.hasData ?? false) ...[
          const SizedBox(height: AppSpacing.l),
          _VeterinarianSection(veterinarian: dose.veterinarian!),
        ],
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            key: Key('vaccination-dose-original-${dose.document.id}'),
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
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String label;
  final String value;
  final bool showImage;

  const _DetailValue({
    required this.label,
    required this.value,
    this.showImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelMaxLines = label.trim().contains(RegExp(r'\s')) ? 2 : 1;
    final uri = Uri.tryParse(value);
    final isImage =
        showImage &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 119,
          child: Text(
            label,
            maxLines: labelMaxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body4.copyWith(color: AppColors.greyBordes),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: isImage
              ? Image.network(
                  value,
                  height: 120,
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    value,
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyTextos,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                    height: 1.45,
                  ),
                ),
        ),
      ],
    );
  }
}

class _VeterinarianSection extends StatelessWidget {
  final SharedFileVeterinarianAnalysisEntity veterinarian;

  const _VeterinarianSection({required this.veterinarian});

  @override
  Widget build(BuildContext context) {
    return _PartySection(
      label: 'Veterinario',
      name: veterinarian.name,
      details: [
        if (veterinarian.clinic.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Clínica',
            value: veterinarian.clinic,
          ),
        if (veterinarian.professionalId.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Registro profesional',
            value: veterinarian.professionalId,
          ),
        ...veterinarian.additionalDetails,
      ],
    );
  }
}

class _TutorSection extends StatelessWidget {
  final SharedFileTutorAnalysisEntity tutor;

  const _TutorSection({required this.tutor});

  @override
  Widget build(BuildContext context) {
    return _PartySection(
      label: 'Propietario',
      name: tutor.name,
      details: [
        if (tutor.identification.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Identificación',
            value: tutor.identification,
          ),
        if (tutor.phoneNumber.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Número celular',
            value: tutor.phoneNumber,
          ),
        ...tutor.additionalDetails,
      ],
    );
  }
}

class _PatientSection extends StatelessWidget {
  final SharedFilePatientAnalysisEntity patient;

  const _PatientSection({required this.patient});

  @override
  Widget build(BuildContext context) {
    return _PartySection(
      label: 'Paciente',
      name: patient.name,
      details: [
        if (patient.recordId.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Animal Record ID',
            value: patient.recordId,
          ),
        if (patient.species.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(
            label: 'Especie',
            value: patient.species,
          ),
        if (patient.breed.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(label: 'Raza', value: patient.breed),
        if (patient.sex.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(label: 'Sexo', value: patient.sex),
        if (patient.age.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(label: 'Edad', value: patient.age),
        if (patient.weight.trim().isNotEmpty)
          SharedFileAnalysisDetailEntity(label: 'Peso', value: patient.weight),
        ...patient.additionalDetails,
      ],
    );
  }
}

class _PartySection extends StatelessWidget {
  final String label;
  final String name;
  final List<SharedFileAnalysisDetailEntity> details;

  const _PartySection({
    required this.label,
    required this.name,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final visible = details.where((detail) => detail.hasData).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name.trim().isNotEmpty)
          RichText(
            text: TextSpan(
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: name,
                  style: AppTypography.body4.copyWith(
                    color: AppColors.primaryAzulClaro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (name.trim().isNotEmpty && visible.isNotEmpty)
          const SizedBox(height: AppSpacing.m),
        for (var index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          _DetailValue(
            label: visible[index].label,
            value: visible[index].value,
          ),
        ],
      ],
    );
  }
}
