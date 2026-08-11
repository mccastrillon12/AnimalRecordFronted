import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/pages/diagnostic_aid_folder_screen.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiagnosticAidFoldersView extends StatelessWidget {
  final String animalId;
  final String query;
  final bool ascending;

  const DiagnosticAidFoldersView({
    super.key,
    required this.animalId,
    required this.query,
    required this.ascending,
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
                      .load(animalId, category: MedicalDocumentCategory.other),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != MedicalDocumentCategory.other) {
          return const SizedBox.shrink();
        }

        final sorted = [...state.documents]
          ..sort((left, right) {
            final comparison = _documentDate(
              left,
            ).compareTo(_documentDate(right));
            return ascending ? comparison : -comparison;
          });
        final normalizedQuery = query.trim().toLowerCase();
        final folders = sorted.indexed
            .map(
              (entry) => _DiagnosticAidFolder(
                position: entry.$1 + 1,
                document: entry.$2,
              ),
            )
            .where(
              (folder) =>
                  normalizedQuery.isEmpty ||
                  folder.position.toString().contains(normalizedQuery) ||
                  folder.document.originalFileName.toLowerCase().contains(
                    normalizedQuery,
                  ),
            )
            .toList(growable: false);

        if (state.documents.isEmpty) {
          return const _DiagnosticAidsEmptyState();
        }
        if (folders.isEmpty) return const _DiagnosticAidsNoResults();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              spacing: AppSpacing.l,
              runSpacing: AppSpacing.l,
              children: folders
                  .map(
                    (folder) => _DiagnosticAidFolderTile(
                      folder: folder,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosticAidFolderScreen(
                            folderNumber: folder.position,
                            documents: [folder.document],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }

  static DateTime _documentDate(MedicalDocumentEntity document) =>
      document.updatedAt ??
      document.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

class _DiagnosticAidFolder {
  final int position;
  final MedicalDocumentEntity document;

  const _DiagnosticAidFolder({required this.position, required this.document});
}

class _DiagnosticAidFolderTile extends StatelessWidget {
  final _DiagnosticAidFolder folder;
  final VoidCallback onTap;

  const _DiagnosticAidFolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ayuda diagnóstica ${folder.position}',
      child: InkWell(
        key: Key('diagnostic-aid-folder-${folder.document.id}'),
        onTap: onTap,
        borderRadius: AppBorders.small(),
        child: SizedBox(
          width: 75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/Grupo 844.svg',
                key: Key('diagnostic-aid-folder-icon-${folder.document.id}'),
                width: 75,
                height: 64,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '${folder.position}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body6.copyWith(
                  color: AppColors.greyTextos,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticAidsEmptyState extends StatelessWidget {
  const _DiagnosticAidsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El registro de ayudas diagnósticas está vacío',
              style: AppTypography.body3.copyWith(
                color: AppColors.greyTextos,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Aquí se podrán visualizar las ayudas diagnósticas que se creen.',
              style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticAidsNoResults extends StatelessWidget {
  const _DiagnosticAidsNoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No se encontraron ayudas diagnósticas.',
        style: AppTypography.body4.copyWith(color: AppColors.greyTextos),
        textAlign: TextAlign.center,
      ),
    );
  }
}
