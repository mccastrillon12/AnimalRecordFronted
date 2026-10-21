import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/animal_medical_documents_view.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/domain/entities/shared_file_analysis_entity.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/analysis_ai_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _vaccinationHeaderActionHeight = 48.0;
const _vaccinationHeaderActionIconSize = 20.0;
const _vaccinationHeaderActionTop = AppSpacing.l;
const _vaccinationNoticeGap = AppSpacing.l;
const _vaccinationExpirationChipHeight = 24.0;
const _vaccinationExpirationNoticeGap = AppSpacing.m;
const _vaccinationEditingWindow = Duration(hours: 48);
const _vaccinationNoticeTopPadding =
    _vaccinationHeaderActionTop +
    ((_vaccinationHeaderActionHeight - _vaccinationHeaderActionIconSize) / 2) +
    _vaccinationHeaderActionIconSize +
    _vaccinationNoticeGap;
const _vaccinationFixedHeaderHeight =
    _vaccinationNoticeTopPadding +
    AnalysisAiNotice.sendHeight +
    _vaccinationNoticeGap;

class VaccinationGroupDetailScreen extends StatefulWidget {
  final String animalId;
  final VaccinationGroupViewData group;
  final VoidCallback onSend;

  const VaccinationGroupDetailScreen({
    super.key,
    required this.animalId,
    required this.group,
    required this.onSend,
  });

  @override
  State<VaccinationGroupDetailScreen> createState() =>
      _VaccinationGroupDetailScreenState();
}

class _VaccinationGroupDetailScreenState
    extends State<VaccinationGroupDetailScreen> {
  final _closeIconKey = GlobalKey();
  MedicalFieldCatalog? _catalog;
  Object? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _catalogError = null);
    try {
      final catalog = await di.sl<GetMedicalFieldCatalogUseCase>()(
        category: MedicalDocumentCategory.vaccinationCard,
      );
      if (mounted) setState(() => _catalog = catalog);
    } catch (error) {
      if (mounted) setState(() => _catalogError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    if (catalog == null) {
      return Scaffold(
        body: Center(
          child: _catalogError == null
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: _loadCatalog,
                  child: const Text('Reintentar'),
                ),
        ),
      );
    }
    final detail = vaccinationDetailViewData(widget.group, catalog);
    final editableDocument = _latestEditableVaccinationDocument(detail.doses);
    final showExpirationOutsideCard = detail.doses.length == 1;

    Widget buildPage(Widget? expiration, Widget? actions) {
      return ModalPageLayout(
        title: '',
        titlePadding: EdgeInsets.zero,
        titleStyle: const TextStyle(fontSize: 0, height: 0),
        fixedTitle: true,
        fixedHeaderHeight:
            _vaccinationFixedHeaderHeight +
            (expiration == null
                ? 0
                : _vaccinationExpirationChipHeight +
                      _vaccinationExpirationNoticeGap),
        trailingTop: AppSpacing.l,
        trailingRight: AppSpacing.l,
        trailingIcon: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            key: _closeIconKey,
            Icons.close,
            size: 24,
            color: AppColors.greyIconos,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        headerChildren: [
          Positioned(
            top: _vaccinationHeaderActionTop,
            left: AppSpacing.l,
            child: GestureDetector(
              key: const Key('export-vaccination-group'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSend,
              child: SizedBox(
                height: _vaccinationHeaderActionHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppIcons.export,
                        width: _vaccinationHeaderActionIconSize,
                        height: _vaccinationHeaderActionIconSize,
                      ),
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
          ),
        ],
        fixedHeaderChild: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            _vaccinationNoticeTopPadding,
            AppSpacing.l,
            _vaccinationNoticeGap,
          ),
          child: expiration == null
              ? const AnalysisAiNotice(key: Key('vaccination-ai-notice'))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    expiration,
                    const SizedBox(height: _vaccinationExpirationNoticeGap),
                    const AnalysisAiNotice(key: Key('vaccination-ai-notice')),
                  ],
                ),
        ),
        bottomSafeAreaColor: AppColors.white,
        bottomPadding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.l,
          0,
        ),
        bottomChild: actions,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: VaccinationRecordList(
            detail: detail,
            animalId: showExpirationOutsideCard ? null : widget.animalId,
            onViewOriginal: _showOriginal,
            onViewOriginalWithText: (document, searchText) =>
                _showOriginal(document, searchText: searchText),
          ),
        ),
      );
    }

    if (editableDocument == null) return buildPage(null, null);

    return MedicalDocumentEditingControls(
      animalId: widget.animalId,
      document: editableDocument,
      category: MedicalDocumentCategory.vaccinationCard,
      instanceKey: editableDocument.id,
      onChanged: () => Navigator.pop(context),
      showExpiration: showExpirationOutsideCard,
      builder: (_, expiration, actions) => buildPage(expiration, actions),
    );
  }

  Future<void> _showOriginal(
    MedicalDocumentEntity document, {
    String? searchText,
  }) async {
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
        closeIconKey: _closeIconKey,
        searchText: searchText,
      );
    } catch (error) {
      if (mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class VaccinationRecordList extends StatelessWidget {
  final VaccinationDetailViewData detail;
  final String? animalId;
  final ValueChanged<MedicalDocumentEntity> onViewOriginal;
  final void Function(MedicalDocumentEntity document, String searchText)?
  onViewOriginalWithText;
  final double recordSpacing;
  final bool groupDoses;

  const VaccinationRecordList({
    super.key,
    required this.detail,
    this.animalId,
    required this.onViewOriginal,
    this.onViewOriginalWithText,
    this.recordSpacing = AppSpacing.xl,
    this.groupDoses = false,
  });

  @override
  Widget build(BuildContext context) {
    if (groupDoses) {
      return _GroupedVaccinationRecordBlock(
        key: Key('vaccination-type-${detail.vaccineName.toLowerCase()}'),
        detail: detail,
        onViewOriginal: _openOriginal,
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
              animalId: animalId,
              editingInstanceKey:
                  '${detail.doses[index].document.id}-$index-inline-expiration',
              onViewOriginal: () => _openOriginal(detail.doses[index]),
            ),
            if (index < detail.doses.length - 1)
              SizedBox(height: recordSpacing),
          ],
        ],
      ),
    );
  }

  void _openOriginal(VaccinationDoseViewData dose) {
    if (onViewOriginalWithText case final callback?) {
      callback(dose.document, _doseSearchText(detail.vaccineName, dose));
    } else {
      onViewOriginal(dose.document);
    }
  }
}

class _GroupedVaccinationRecordBlock extends StatelessWidget {
  final VaccinationDetailViewData detail;
  final ValueChanged<VaccinationDoseViewData> onViewOriginal;

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
                onViewOriginal: () => onViewOriginal(detail.doses[index]),
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

String _doseSearchText(String vaccineName, VaccinationDoseViewData dose) {
  return [
    vaccineName,
    dose.applicationDate,
    for (final detail in dose.details)
      if (detail.hasData &&
          detail.value.trim() != dose.applicationDate.trim() &&
          !(detail.label == 'Etiqueta' &&
              (Uri.tryParse(detail.value)?.hasScheme ?? false)))
        detail.value,
    dose.nextDoseDate,
  ].where((value) => value.trim().isNotEmpty).join('\n');
}

class _VaccinationRecordBlock extends StatelessWidget {
  final String vaccineName;
  final VaccinationDoseViewData dose;
  final String? animalId;
  final String editingInstanceKey;
  final VoidCallback onViewOriginal;

  const _VaccinationRecordBlock({
    super.key,
    required this.vaccineName,
    required this.dose,
    required this.animalId,
    required this.editingInstanceKey,
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
        child: animalId != null
            ? MedicalDocumentEditingControls(
                animalId: animalId!,
                document: dose.document,
                category: MedicalDocumentCategory.vaccinationCard,
                instanceKey: editingInstanceKey,
                showActions: false,
                builder: (_, expiration, _) => _DoseSection(
                  vaccineName: vaccineName,
                  dose: dose,
                  expiration: expiration,
                  onViewOriginal: onViewOriginal,
                ),
              )
            : _DoseSection(
                vaccineName: vaccineName,
                dose: dose,
                onViewOriginal: onViewOriginal,
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
  final Widget? expiration;

  const _DoseSection({
    required this.vaccineName,
    required this.dose,
    required this.onViewOriginal,
    this.showHeader = true,
    this.headerTitle = 'Detalle de vacunación',
    this.expiration,
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
                SvgPicture.asset(
                  AppIcons.clipboardImport,
                  width: 17,
                  height: 21,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryAzulClaro,
                    BlendMode.srcIn,
                  ),
                ),
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
                  vaccinationDisplayName(vaccineName),
                  style: AppTypography.body4.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
                if (expiration != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  expiration!,
                ],
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
        if (dose.veterinarian?.hasData ?? false) ...[
          const SizedBox(height: AppSpacing.l),
          _VeterinarianSection(veterinarian: dose.veterinarian!),
        ],
      ],
    );
  }
}

MedicalDocumentEntity? _latestEditableVaccinationDocument(
  Iterable<VaccinationDoseViewData> doses, {
  DateTime? now,
}) {
  final documentsById = <String, MedicalDocumentEntity>{};
  for (final dose in doses) {
    documentsById[dose.document.id] = dose.document;
  }

  final currentTime = now ?? DateTime.now();
  final editableDocuments = documentsById.values.where((document) {
    final deadline = _vaccinationEditingDeadline(document);
    return document.canReplace &&
        deadline != null &&
        deadline.isAfter(currentTime);
  }).toList();
  editableDocuments.sort((left, right) {
    final rightUploadTime = _vaccinationUploadTime(right);
    final leftUploadTime = _vaccinationUploadTime(left);
    final byUploadTime = rightUploadTime.compareTo(leftUploadTime);
    return byUploadTime != 0 ? byUploadTime : right.id.compareTo(left.id);
  });
  return editableDocuments.isEmpty ? null : editableDocuments.first;
}

DateTime? _vaccinationEditingDeadline(MedicalDocumentEntity document) {
  final updatedAt = document.updatedAt;
  if (updatedAt != null) return updatedAt.add(_vaccinationEditingWindow);
  return document.replacementDeadline;
}

DateTime _vaccinationUploadTime(MedicalDocumentEntity document) {
  return document.updatedAt ??
      document.acceptedAt ??
      document.createdAt ??
      document.replacementDeadline?.subtract(_vaccinationEditingWindow) ??
      DateTime.fromMillisecondsSinceEpoch(0);
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
