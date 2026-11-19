import 'package:animal_record/core/constants/app_icons.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/app_back_button.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/utils/animal_family_label.dart';
import 'package:animal_record/features/home/presentation/utils/transfer_status_label.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_animals_summary.dart';
import 'package:flutter/material.dart';

class TransferAcceptanceView extends StatelessWidget {
  final TransferRequest? request;
  final List<TransferItem> items;
  final Set<String> selectedAnimalIds;
  final bool loading;
  final bool hasMoreAnimals;
  final String? error;
  final String? acceptUnavailableMessage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onLoadMore;
  final ValueChanged<String>? onToggleAnimal;
  final VoidCallback? onToggleAll;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final void Function(TransferItem, String)? onImageError;

  const TransferAcceptanceView({
    super.key,
    required this.request,
    required this.items,
    required this.selectedAnimalIds,
    required this.loading,
    required this.hasMoreAnimals,
    required this.error,
    required this.acceptUnavailableMessage,
    required this.onBack,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onToggleAnimal,
    required this.onToggleAll,
    required this.onAccept,
    required this.onReject,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    final transfer = request;
    final isPending = transfer?.status == 'PENDING';
    final animalCount = transfer != null && transfer.animalCount > 0
        ? transfer.animalCount
        : items.length;
    final multipleAnimals = animalCount > 1;
    return ModalPageLayout(
      title: 'Transferencia de animal(es)',
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        96,
        AppSpacing.l,
        AppSpacing.xl + AppSpacing.xs,
      ),
      trailingIcon: const SizedBox.shrink(),
      bottomPadding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.m,
      ),
      bottomChild: _bottomActions(isPending, multipleAnimals),
      headerChildren: [
        PositionedDirectional(
          top: AppSpacing.xl,
          start: AppSpacing.l,
          child: Tooltip(
            message: 'Volver',
            child: SizedBox.square(
              dimension: kMinInteractiveDimension,
              child: AppBackButton(
                onPressed: onBack,
                color: AppColors.greyMedio,
                alignment: AlignmentDirectional.topStart,
              ),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading && transfer == null)
              const Center(child: CircularProgressIndicator()),
            if (error != null) ...[
              Text(
                error!,
                style: AppTypography.body6.copyWith(color: AppColors.error),
              ),
              if (transfer == null)
                TextButton(
                  onPressed: loading ? null : onRefresh,
                  child: const Text('Reintentar'),
                ),
            ],
            if (transfer != null) ...[
              Text.rich(
                TextSpan(
                  text: 'El usuario ',
                  children: [
                    TextSpan(
                      text: transfer.senderName.isEmpty
                          ? 'remitente'
                          : transfer.senderName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(
                      text:
                          ' le ha hecho la transferencia de '
                          'los siguientes animales. Acéptelos '
                          'para visualizar y gestionar su información.',
                    ),
                  ],
                ),
                style: AppTypography.body4,
              ),
              const SizedBox(height: AppSpacing.l),
              _AcceptanceAnimals(
                items: items,
                animalCount: animalCount,
                selectedAnimalIds: selectedAnimalIds,
                hasMoreAnimals: hasMoreAnimals,
                onToggleAnimal: onToggleAnimal,
                onToggleAll: onToggleAll,
                onImageError: onImageError,
              ),
              if (hasMoreAnimals)
                TextButton(
                  onPressed: onLoadMore,
                  child: const Text('Cargar más animales'),
                ),
              if (!isPending) ...[
                const SizedBox(height: AppSpacing.l),
                Text(
                  transferStatusLabel(transfer.status),
                  style: AppTypography.body5,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomActions(bool isPending, bool multipleAnimals) {
    if (!isPending) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Nota: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: multipleAnimals
                    ? 'Si no reconoce algún animal transferido, puede '
                          'seleccionarlo y rechazarlo. El resto se aceptarán '
                          'automáticamente.'
                    : 'Si usted no reconoce el animal transferido, '
                          'por favor rechácelo, se le devolverá al usuario '
                          'original.',
              ),
            ],
          ),
          style: AppTypography.body6.copyWith(color: AppColors.greyNegro),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (acceptUnavailableMessage case final message?) ...[
          Text(message, style: AppTypography.body6),
          const SizedBox(height: AppSpacing.xs),
        ],
        CustomButton(
          text: multipleAnimals ? 'Aceptar todo' : 'Aceptar',
          onPressed: onAccept,
        ),
        const SizedBox(height: AppSpacing.m),
        OutlinedButton(
          onPressed: onReject,
          style:
              OutlinedButton.styleFrom(
                backgroundColor: AppColors.bgHielo,
                disabledBackgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryFrances,
                disabledForegroundColor: AppColors.greyBordes,
                minimumSize: const Size(double.infinity, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTypography.body3,
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorders.medium(),
                ),
              ).copyWith(
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.disabled)
                        ? AppColors.greyBordes
                        : AppColors.primaryFrances,
                  ),
                ),
              ),
          child: Text(multipleAnimals ? 'Rechazar seleccionados' : 'Rechazar'),
        ),
      ],
    );
  }
}

class _AcceptanceAnimals extends StatefulWidget {
  final List<TransferItem> items;
  final int animalCount;
  final Set<String> selectedAnimalIds;
  final bool hasMoreAnimals;
  final ValueChanged<String>? onToggleAnimal;
  final VoidCallback? onToggleAll;
  final void Function(TransferItem, String)? onImageError;

  const _AcceptanceAnimals({
    required this.items,
    required this.animalCount,
    required this.selectedAnimalIds,
    required this.hasMoreAnimals,
    required this.onToggleAnimal,
    required this.onToggleAll,
    this.onImageError,
  });

  @override
  State<_AcceptanceAnimals> createState() => _AcceptanceAnimalsState();
}

class _AcceptanceAnimalsState extends State<_AcceptanceAnimals> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final multipleAnimals = widget.animalCount > 1;
    final pendingIds = items
        .where((item) => item.status == 'PENDING')
        .map((item) => item.animalId)
        .toSet();
    final byAnimalId = {for (final item in items) item.animalId: item};
    return TransferAnimalsSummary(
      animals: items.map(_animalModel).toList(growable: false),
      animalCount: widget.animalCount,
      expanded: _expanded,
      expandedIcon: Icons.chevron_right,
      onToggle: () => setState(() => _expanded = !_expanded),
      headerLeading: multipleAnimals
          ? _TransferCheckbox(
              label: 'Seleccionar todos los animales',
              value:
                  !widget.hasMoreAnimals &&
                  pendingIds.isNotEmpty &&
                  widget.selectedAnimalIds.containsAll(pendingIds),
              onChanged: widget.onToggleAll == null
                  ? null
                  : (_) => widget.onToggleAll!(),
            )
          : null,
      animalBuilder: (animal) => _buildAnimalRow(
        byAnimalId[animal.id]!,
        animal,
        multipleAnimals: multipleAnimals,
      ),
    );
  }

  Widget _buildAnimalRow(
    TransferItem item,
    AnimalModel animal, {
    required bool multipleAnimals,
  }) {
    final toggle = widget.onToggleAnimal;
    final onTap = multipleAnimals && toggle != null && item.status == 'PENDING'
        ? () => toggle(item.animalId)
        : null;
    final sex = switch (item.animalSex?.trim().toUpperCase()) {
      'MALE' || 'MACHO' => 'Macho',
      'FEMALE' || 'HEMBRA' => 'Hembra',
      _ => _available(item.animalSex),
    };
    return TransferAnimalSummaryRow(
      key: ValueKey(item.id),
      animal: animal,
      unknownFamilyIconPath: AppIcons.animals,
      onImageError: widget.onImageError == null
          ? null
          : (failedUrl) => widget.onImageError!(item, failedUrl),
      detailsText: '${_available(item.animalBreed)} - $sex',
      supplementaryText: item.status == 'PENDING'
          ? null
          : transferStatusLabel(item.status),
      onTap: onTap,
      leading: !multipleAnimals
          ? null
          : _TransferCheckbox(
              label: 'Seleccionar ${animal.name}',
              value: widget.selectedAnimalIds.contains(item.animalId),
              onChanged: onTap == null ? null : (_) => onTap(),
            ),
    );
  }
}

class _TransferCheckbox extends StatelessWidget {
  const _TransferCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    const edge = 22.0;
    const width = 44.0;
    const scale = edge / Checkbox.width;
    final direction = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    return SizedBox(
      width: width,
      height: width,
      child: Transform.translate(
        offset: Offset(direction * (edge - width) / 2, 0),
        transformHitTests: false,
        child: Transform.scale(
          scale: scale,
          transformHitTests: false,
          child: Checkbox(
            semanticLabel: label,
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryFrances,
            checkColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppBorders.radiusSmall / scale,
              ),
            ),
            side: WidgetStateBorderSide.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const BorderSide(
                      color: AppColors.primaryFrances,
                      width: 1 / scale,
                    )
                  : const BorderSide(
                      color: AppColors.greyBordes,
                      width: 1 / scale,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

AnimalModel _animalModel(TransferItem item) => AnimalModel(
  id: item.animalId,
  name: _available(item.animalName),
  code: _available(item.animalCode),
  family: item.animalSpecies?.trim().isNotEmpty == true
      ? animalFamilyLabel(item.animalSpecies!)
      : animalFamilyFromCode(item.animalCode),
  breed: item.animalBreed,
  sex: item.animalSex,
  ageDisplay: _ageLabel(item.animalAge),
  imageUrl: item.animalImageUrl,
);

const _unavailable = 'No disponible';

String _available(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? _unavailable : text;
}

String _ageLabel(TransferAnimalAge? age) => switch (age) {
  ExactTransferAnimalAge(:final months) => _completedAge(months),
  ApproximateTransferAnimalAge(:final minMonths, :final maxMonths) =>
    'Aprox. $minMonths–$maxMonths meses',
  null => _unavailable,
};

String _completedAge(int months) {
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  return [
    if (years > 0) '$years ${years == 1 ? 'año' : 'años'}',
    if (years == 0 || remainingMonths > 0)
      '$remainingMonths ${remainingMonths == 1 ? 'mes' : 'meses'}',
  ].join(' ');
}
