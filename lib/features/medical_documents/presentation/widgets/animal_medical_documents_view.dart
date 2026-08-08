import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_pdf_adapter.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:animal_record/features/shared_files/presentation/pages/shared_file_analysis_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalMedicalDocumentsView extends StatelessWidget {
  final String animalId;
  final MedicalDocumentCategory category;
  final String emptyTitle;
  final String emptyDescription;
  final String searchQuery;
  final double emptyBottomOffset;

  const AnimalMedicalDocumentsView({
    super.key,
    required this.animalId,
    required this.category,
    required this.emptyTitle,
    required this.emptyDescription,
    this.searchQuery = '',
    this.emptyBottomOffset = 100,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AnimalMedicalDocumentsCubit,
      AnimalMedicalDocumentsState
    >(
      builder: (context, state) {
        if (state is AnimalMedicalDocumentsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryFrances),
          );
        }
        if (state is AnimalMedicalDocumentsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTypography.body4,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextButton(
                    onPressed: () => context
                        .read<AnimalMedicalDocumentsCubit>()
                        .load(animalId, category: category),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != category) {
          return const SizedBox.shrink();
        }

        final query = searchQuery.trim().toLowerCase();
        final documents = state.documents
            .where(
              (document) =>
                  query.isEmpty ||
                  _searchableDocumentText(document).contains(query),
            )
            .toList(growable: false);
        if (documents.isEmpty) {
          return _EmptyState(
            title: emptyTitle,
            description: emptyDescription,
            bottomOffset: emptyBottomOffset,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          itemCount: documents.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) => index == 0
              ? const _AiFeedbackBanner()
              : _MedicalDocumentCard(
                  document: documents[index - 1],
                  category: category,
                ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final double bottomOffset;

  const _EmptyState({
    required this.title,
    required this.description,
    required this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          bottomOffset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.body3.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              description,
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalDocumentCard extends StatelessWidget {
  final MedicalDocumentEntity document;
  final MedicalDocumentCategory category;

  const _MedicalDocumentCard({required this.document, required this.category});

  @override
  Widget build(BuildContext context) {
    final extraction = document.validatedExtraction;
    final date = displayMedicalDocumentDate(extraction?.documentDate);
    final description = _documentDescription(document);
    final number = _documentNumber(document);
    final title = [
      'Adjunto: ${document.finalCategory?.label ?? 'Documento médico'}',
      if (number.isNotEmpty) number,
    ].join(' ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.bgBlancoAntiFlash,
        borderRadius: AppBorders.small(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                AppIcons.clipboardImport,
                width: AppSpacing.iconSizeSmall,
                height: AppSpacing.iconSizeSmall,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body3.copyWith(
                    color: AppColors.greyTextos,
                  ),
                ),
              ),
            ],
          ),
          if (date.isNotEmpty ||
              document.originalFileName.trim().isNotEmpty ||
              description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.iconSizeSmall + AppSpacing.m,
              ),
              child: Column(
                children: [
                  if (date.isNotEmpty)
                    _DocumentCardValue(label: 'Fecha:', value: date),
                  if (document.originalFileName.trim().isNotEmpty)
                    _DocumentCardValue(
                      label: 'Archivo:',
                      value: document.originalFileName,
                    ),
                  if (description.isNotEmpty)
                    _DocumentCardValue(
                      label: 'Descripción:',
                      value: description,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              key: Key('medical-document-detail-${document.id}'),
              onTap: extraction == null ? null : () => _showDetail(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver detalle',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.greyMedio,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SvgPicture.asset(
                      AppIcons.arrowRight,
                      width: AppSpacing.iconSizeSmall,
                      height: AppSpacing.iconSizeSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetail(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (detailContext) => SharedFileSendScreen(
          analysis: medicalDocumentToPdfAnalysis(document: document),
          onViewOriginal: () => _showOriginal(detailContext),
          resolveOriginalUri: () =>
              di.sl<GetMedicalDocumentDownloadUriUseCase>()(document.id),
          actionLabel: medicalDocumentSendActionLabel(category),
        ),
      ),
    );
  }

  Future<void> _showOriginal(BuildContext context) async {
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
      if (context.mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class _DocumentCardValue extends StatelessWidget {
  final String label;
  final String value;

  const _DocumentCardValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AiFeedbackValue { useful, notUseful }

class _AiFeedbackBanner extends StatefulWidget {
  const _AiFeedbackBanner();

  @override
  State<_AiFeedbackBanner> createState() => _AiFeedbackBannerState();
}

class _AiFeedbackBannerState extends State<_AiFeedbackBanner> {
  _AiFeedbackValue? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: AppColors.aiAnalysisGradient,
        borderRadius: AppBorders.small(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¿La ayuda de la IA te fue útil\npara leer tu documento?',
              style: AppTypography.body6.copyWith(
                color: const Color.fromARGB(255, 0, 0, 0),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          _AiFeedbackButton(
            key: const Key('medical-document-ai-not-useful'),
            icon: Icons.thumb_down_alt,
            selected: _selected == _AiFeedbackValue.notUseful,
            onTap: () => setState(
              () => _selected = _selected == _AiFeedbackValue.notUseful
                  ? null
                  : _AiFeedbackValue.notUseful,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          _AiFeedbackButton(
            key: const Key('medical-document-ai-useful'),
            icon: Icons.thumb_up_alt,
            selected: _selected == _AiFeedbackValue.useful,
            onTap: () => setState(
              () => _selected = _selected == _AiFeedbackValue.useful
                  ? null
                  : _AiFeedbackValue.useful,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeedbackButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AiFeedbackButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
}

String _documentNumber(MedicalDocumentEntity document) {
  final additionalFields =
      document.validatedExtraction?.additionalFields ??
      const <String, dynamic>{};
  for (final entry in additionalFields.entries) {
    if (const {
      'documentnumber',
      'prescriptionnumber',
      'formulanumber',
      'numeroformula',
      'numerodocumento',
    }.contains(_normalizedFieldKey(entry.key))) {
      final value = _valueText(entry.value).trim();
      if (value.isNotEmpty) return value.startsWith('N°') ? value : 'N° $value';
    }
  }
  final value = document.id.replaceAll('-', '').trim();
  if (value.isEmpty) return '';
  final end = value.length < 8 ? value.length : 8;
  return 'N° ${value.substring(0, end)}';
}

String _documentDescription(MedicalDocumentEntity document) {
  final extraction = document.validatedExtraction;
  final additionalFields =
      extraction?.additionalFields ?? const <String, dynamic>{};
  for (final entry in additionalFields.entries) {
    if (const {
      'description',
      'descripcion',
    }.contains(_normalizedFieldKey(entry.key))) {
      final value = _valueText(entry.value).trim();
      if (value.isNotEmpty) return value;
    }
  }
  final summary = extraction?.summary?.trim() ?? '';
  if (summary.isNotEmpty) return summary;
  for (final detected in document.detectedCategories) {
    if (detected.category == document.finalCategory &&
        (detected.summary?.trim().isNotEmpty ?? false)) {
      return detected.summary!.trim();
    }
  }
  return '';
}

String _normalizedFieldKey(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _searchableDocumentText(MedicalDocumentEntity document) {
  final extraction = document.validatedExtraction;
  return [
    document.originalFileName,
    document.finalCategory?.label,
    extraction?.summary,
    extraction?.documentDate,
    ...?extraction?.patientHints,
    ...?extraction?.diagnoses.expand(_itemSearchValues),
    ...?extraction?.medications.expand(_itemSearchValues),
    ...?extraction?.vaccinations.expand(_itemSearchValues),
    ...?extraction?.medicalOrders.expand(_itemSearchValues),
    ...?extraction?.diagnosticResults.expand(_itemSearchValues),
    ...?extraction?.clinicalHistory?.values,
    ...?extraction?.referral?.values,
    ...?extraction?.additionalFields.values,
  ].whereType<Object>().map(_valueText).join(' ').toLowerCase();
}

Iterable<Object?> _itemSearchValues(MedicalDocumentItemEntity item) => [
  item.id,
  ...item.fields.values,
];

String _valueText(Object? value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value.map(_valueText).where((item) => item.isNotEmpty).join(' ');
  }
  if (value is Map) {
    return value.entries
        .where((entry) => entry.key != 'source' && entry.key != 'confidence')
        .map((entry) => _valueText(entry.value))
        .where((item) => item.isNotEmpty)
        .join(' ');
  }
  return value.toString().trim();
}
