import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_group_detail_screen.dart';
import 'package:animal_record/features/home/presentation/pages/vaccination_card_screen.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/presentation/cubit/animal_medical_documents_cubit.dart';
import 'package:animal_record/features/medical_documents/presentation/mappers/vaccination_group_mapper.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:animal_record/features/medical_documents/presentation/widgets/medical_document_ai_feedback_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VaccinationGroupsView extends StatelessWidget {
  final AnimalModel animal;
  final String searchQuery;
  final bool? alphabeticalSortAscending;
  final bool showAiFeedback;
  final int aiFeedbackRequestId;
  final bool initialAiFeedbackResponded;
  final VoidCallback? onAiFeedbackDismissed;
  final Future<void> Function()? onAiFeedbackSubmitted;

  const VaccinationGroupsView({
    super.key,
    required this.animal,
    this.searchQuery = '',
    this.alphabeticalSortAscending,
    this.showAiFeedback = false,
    this.aiFeedbackRequestId = 0,
    this.initialAiFeedbackResponded = false,
    this.onAiFeedbackDismissed,
    this.onAiFeedbackSubmitted,
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
            child: TextButton(
              onPressed: () => context.read<AnimalMedicalDocumentsCubit>().load(
                animal.id,
                category: MedicalDocumentCategory.vaccinationCard,
              ),
              child: const Text('Reintentar'),
            ),
          );
        }
        if (state is! AnimalMedicalDocumentsLoaded ||
            state.category != MedicalDocumentCategory.vaccinationCard) {
          return const SizedBox.shrink();
        }

        final allGroups = groupVaccinations(state.documents);
        final shouldShowAiFeedback = showAiFeedback && allGroups.isNotEmpty;
        if (allGroups.isEmpty && !shouldShowAiFeedback) {
          return const _VaccinationEmptyState();
        }

        final query = searchQuery.trim().toLowerCase();
        final filteredGroups = allGroups
            .where((group) => query.isEmpty || group.searchText.contains(query))
            .toList(growable: false);
        final groups = alphabeticalSortAscending == null
            ? sortVaccinationGroupsByLatest(filteredGroups)
            : [...filteredGroups];
        if (alphabeticalSortAscending case final ascending?) {
          groups.sort(
            ascending
                ? (left, right) => left.title.compareTo(right.title)
                : (left, right) => right.title.compareTo(left.title),
          );
        }
        if (groups.isEmpty && !shouldShowAiFeedback) {
          return const _VaccinationNoResultsState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 88),
          itemCount: groups.length + (shouldShowAiFeedback ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) => shouldShowAiFeedback && index == 0
              ? MedicalDocumentAiFeedbackBanner(
                  key: ValueKey(aiFeedbackRequestId),
                  initialHasResponded: initialAiFeedbackResponded,
                  onDismissed: onAiFeedbackDismissed,
                  onSubmitted: onAiFeedbackSubmitted,
                )
              : _VaccinationGroupCard(
                  group: groups[index - (shouldShowAiFeedback ? 1 : 0)],
                  onDetail: () => _showDetail(
                    context,
                    groups[index - (shouldShowAiFeedback ? 1 : 0)],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    VaccinationGroupViewData group,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinationGroupDetailScreen(
          group: group,
          onSend: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AnimalMedicalDocumentsCubit>(),
                child: VaccinationCardScreen(
                  animal: animal,
                  selectedGroup: group,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VaccinationGroupCard extends StatelessWidget {
  final VaccinationGroupViewData group;
  final VoidCallback onDetail;

  const _VaccinationGroupCard({required this.group, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final latest = group.latest;
    final hasDates =
        latest.applicationDate.isNotEmpty || latest.nextDoseDate.isNotEmpty;
    return MedicalDocumentCard(
      key: Key('vaccination-group-${group.key}'),
      onTap: onDetail,
      headerCrossAxisAlignment: CrossAxisAlignment.center,
      trailingSpacing: 0,
      leading: SvgPicture.asset(
        AppIcons.documentUpload,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryAzulClaro,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        vaccinationDisplayName(group.title),
        style: AppTypography.body3.copyWith(color: AppColors.greyTextos),
      ),
      trailing: Container(
        constraints: const BoxConstraints(minWidth: 21, minHeight: 22),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${group.count}',
          style: AppTypography.body6.copyWith(
            color: AppColors.primaryFrances,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: hasDates
          ? Padding(
              padding: const EdgeInsets.only(left: 29),
              child: Column(
                children: [
                  if (latest.applicationDate.isNotEmpty)
                    _VaccinationValue(
                      label: '${latest.applicationDateLabel}:',
                      value: latest.applicationDate,
                    ),
                  if (latest.nextDoseDate.isNotEmpty)
                    _VaccinationValue(
                      label: '${latest.nextDoseDateLabel}:',
                      value: latest.nextDoseDate,
                    ),
                ],
              ),
            )
          : null,
      footer: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          key: Key('vaccination-group-detail-${group.key}'),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
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
              const Icon(
                Icons.chevron_right,
                size: AppSpacing.iconSizeSmall,
                color: AppColors.greyIconos,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaccinationValue extends StatelessWidget {
  final String label;
  final String value;

  const _VaccinationValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.body6.copyWith(color: AppColors.greyBordes),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body6.copyWith(color: AppColors.greyTextos),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccinationEmptyState extends StatelessWidget {
  const _VaccinationEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _VaccinationMessage(
      title: 'El registro de vacunas está vacío',
      description: 'Aquí se podrán visualizar las vacunas que se creen.',
    );
  }
}

class _VaccinationNoResultsState extends StatelessWidget {
  const _VaccinationNoResultsState();

  @override
  Widget build(BuildContext context) {
    return const _VaccinationMessage(
      title: 'No se encontraron vacunas',
      description: 'Intente realizar una búsqueda diferente.',
    );
  }
}

class _VaccinationMessage extends StatelessWidget {
  final String title;
  final String description;

  const _VaccinationMessage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, 100),
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
