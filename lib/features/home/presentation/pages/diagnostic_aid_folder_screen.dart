import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_shadows.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/services/medical_document_file_saver.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/medical_document_date_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_original_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiagnosticAidFolderScreen extends StatelessWidget {
  final int folderNumber;
  final List<MedicalDocumentEntity> documents;

  const DiagnosticAidFolderScreen({
    super.key,
    required this.folderNumber,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundDegrade,
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: const SizedBox(height: AppSpacing.l),
              ),
              Expanded(
                child: Container(
                  key: const Key('diagnostic-aid-folder-panel'),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorders.radiusXXLarge),
                      topRight: Radius.circular(AppBorders.radiusXXLarge),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.l,
                          AppSpacing.xl,
                          AppSpacing.l,
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              key: const Key('diagnostic-aid-folder-back'),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: AppSpacing.iconSizeSmall,
                                height: AppSpacing.iconSizeSmall,
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.greyIconos,
                              ),
                            ),
                            IconButton(
                              key: const Key('diagnostic-aid-folder-close'),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: AppSpacing.iconSizeSmall,
                                height: AppSpacing.iconSizeSmall,
                              ),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.greyIconos,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Ayudas diagnósticas',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Carpeta $folderNumber',
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyBordes,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.l,
                            0,
                            AppSpacing.l,
                            AppSpacing.xl,
                          ),
                          itemCount: documents.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.m),
                          itemBuilder: (context, index) =>
                              _DiagnosticAidDocumentCard(
                                index: index,
                                document: documents[index],
                                onTap: () =>
                                    _showOriginal(context, documents[index]),
                                onDownload: () => _downloadOriginal(
                                  context,
                                  documents[index],
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOriginal(
    BuildContext context,
    MedicalDocumentEntity document,
  ) async {
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

  Future<void> _downloadOriginal(
    BuildContext context,
    MedicalDocumentEntity document,
  ) async {
    try {
      final remoteUri = await di.sl<GetMedicalDocumentDownloadUriUseCase>()(
        document.id,
      );
      final saved = await di.sl<SaveMedicalDocumentOriginalUseCase>()(
        MedicalDocumentFileSaveRequest(
          fileName: document.originalFileName,
          remoteUri: remoteUri,
        ),
      );
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo guardado correctamente.')),
        );
      }
    } catch (error) {
      if (context.mounted) ErrorDisplay.showError(context, error.toString());
    }
  }
}

class _DiagnosticAidDocumentCard extends StatelessWidget {
  final int index;
  final MedicalDocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _DiagnosticAidDocumentCard({
    required this.index,
    required this.document,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('diagnostic-aid-document-shadow-${document.id}'),
      decoration: BoxDecoration(
        borderRadius: AppBorders.large(),
        boxShadow: const [AppShadows.card],
      ),
      child: Material(
        color: AppColors.bgBlancoAntiFlash,
        borderRadius: AppBorders.large(),
        child: InkWell(
          key: Key('diagnostic-aid-document-${document.id}'),
          onTap: onTap,
          borderRadius: AppBorders.large(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.iconSizeMedium,
                  height: AppSpacing.iconSizeMedium,
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.clipboardImport,
                      key: Key('diagnostic-aid-document-icon-${document.id}'),
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ayuda diagnóstica ${index + 1}',
                        style: AppTypography.body3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _documentDate(document),
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyBordes,
                        ),
                      ),
                    ],
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    key: Key('diagnostic-aid-document-menu-${document.id}'),
                    padding: EdgeInsets.zero,
                    offset: const Offset(-175, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorders.radiusMedium,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 203,
                      maxWidth: 203,
                    ),
                    color: AppColors.white,
                    elevation: 4,
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.primaryFrances,
                    ),
                    onSelected: (_) => onDownload(),
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        key: Key('download-diagnostic-aid-${document.id}'),
                        value: 'download',
                        height: 47,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppIcons.receiveSquare,
                              width: AppSpacing.iconSizeSmall,
                              height: AppSpacing.iconSizeSmall,
                              colorFilter: const ColorFilter.mode(
                                AppColors.greyMedio,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Descargar archivo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.greyTextos,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _documentDate(MedicalDocumentEntity document) {
    final localDate = document.updatedAt ?? document.createdAt;
    if (localDate != null) return formatMedicalDocumentDate(localDate);
    return displayMedicalDocumentDate(
      document.validatedExtraction?.documentDate,
    );
  }
}
