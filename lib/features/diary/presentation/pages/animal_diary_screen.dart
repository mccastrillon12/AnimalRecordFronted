import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/feedback/custom_snackbar.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/core/widgets/media/audio_player_widget.dart';

class AnimalDiaryScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalDiaryScreen({super.key, required this.animal});

  @override
  State<AnimalDiaryScreen> createState() => _AnimalDiaryScreenState();
}

class _AnimalDiaryScreenState extends State<AnimalDiaryScreen> {
  bool _showSuccessSnackbar = false;
  String _snackbarMessage = 'Nota guardada exitosamente.';

  @override
  void initState() {
    super.initState();
    context.read<DiaryCubit>().getDiaryEntries(widget.animal.id);
  }

  void _navigateToCreate() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.animalDiaryCreate,
      arguments: widget.animal,
    );

    if (result == true && mounted) {
      context.read<DiaryCubit>().getDiaryEntries(widget.animal.id);
      _showSnackbar('Nota guardada exitosamente.');
    }
  }

  void _navigateToEdit(DiaryEntryEntity entry) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.animalDiaryCreate,
      arguments: {
        'animal': widget.animal,
        'entry': entry,
      },
    );

    if (result == true && mounted) {
      context.read<DiaryCubit>().getDiaryEntries(widget.animal.id);
      _showSnackbar('Nota actualizada exitosamente.');
    }
  }

  void _showSnackbar(String message) {
    setState(() {
      _snackbarMessage = message;
      _showSuccessSnackbar = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccessSnackbar = false);
    });
  }

  void _confirmDelete(DiaryEntryEntity entry) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Eliminar nota',
        description: '¿Estás seguro de que deseas eliminar esta nota? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar',
        onConfirm: () {
          context.read<DiaryCubit>().deleteDiaryEntry(
            animalId: widget.animal.id,
            entryId: entry.id,
          );
        },
      ),
    );
  }

  void _handleAttachmentTap(DiaryAttachmentEntity attachment, DiaryEntryEntity entry) {
    if (attachment.fileType == 'image') {
      showDialog(
        context: context,
        builder: (_) => ImagePreviewDialog(imageUrl: attachment.url),
      );
    } else if (attachment.fileType == 'audio') {
      final audios = entry.attachments.where((a) => a.fileType == 'audio').toList();
      final initialIndex = audios.indexWhere((a) => a.id == attachment.id);
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AudioPlayerWidget(
              audioUrls: audios.map((a) => a.url).toList(),
              fileNames: audios.map((a) => a.fileName).toList(),
              initialIndex: initialIndex >= 0 ? initialIndex : 0,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiaryCubit, DiaryState>(
      listener: (context, state) {
        if (state is DiaryEntryDeleted) {
          _showSnackbar('Nota eliminada exitosamente.');
        } else if (state is DiaryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: CustomSnackBar(
                message: state.message,
                isError: true,
              ),
            ),
          );
          // Restore to loaded
          context.read<DiaryCubit>().resetToLoaded();
        }
      },
      child: BlocBuilder<DiaryCubit, DiaryState>(
        builder: (context, state) {
          final bool hasEntries =
              state is DiaryLoaded && state.entries.isNotEmpty;

          return Stack(
            children: [
              ModalPageLayout(
                title: 'Diario',
                bottomChild: hasEntries
                    ? const SizedBox.shrink()
                    : CustomButton(
                        text: '+ Nueva nota',
                        onPressed: _navigateToCreate,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: _buildBody(state),
                ),
              ),

              // FAB for list view
              if (hasEntries)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: _navigateToCreate,
                    backgroundColor: AppColors.primaryFrances,
                    elevation: 4,
                    child: const Icon(Icons.add, color: AppColors.white, size: 28),
                  ),
                ),

              // Success snackbar overlay
              if (_showSuccessSnackbar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                      child: CustomSnackBar(
                        message: _snackbarMessage,
                        onClose: () =>
                            setState(() => _showSuccessSnackbar = false),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(DiaryState state) {
    if (state is DiaryLoading || state is DiaryEntrySaving) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is DiaryLoaded) {
      if (state.entries.isEmpty) return _buildEmptyState();
      return _buildEntriesList(state.entries);
    }

    if (state is DiaryEntryDeleted) {
      if (state.allEntries.isEmpty) return _buildEmptyState();
      return _buildEntriesList(state.allEntries);
    }

    if (state is DiaryError) {
      return Center(
        child: Text(
          state.message,
          style: AppTypography.body4.copyWith(color: AppColors.errorRojo),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Empty state ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.greyDelineante,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.animal.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.animal.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: Icon(Icons.pets, color: AppColors.greyBordes, size: 50),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.pets, color: AppColors.greyBordes, size: 50),
                  ),
                )
              : const Center(
                  child: Icon(Icons.pets, color: AppColors.greyBordes, size: 50),
                ),
        ),
        const SizedBox(height: 32),
        Text(
          'Crea la primer nota en tu diario',
          style: AppTypography.body3.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.greyNegro,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.body4.copyWith(
              color: AppColors.greyMedio,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: 'Guarda notas, fotos y comentarios\nsobre la evolución, salud y momentos\nimportantes de tu animal.\n',
              ),
              TextSpan(
                text: 'Max X notas.',
                style: AppTypography.body4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyNegro,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Entries list (grouped by month) ──────────────────────────

  Widget _buildEntriesList(List<DiaryEntryEntity> entries) {
    final List<Widget> children = [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTypography.body4.copyWith(
            color: AppColors.greyMedio,
            height: 1.5,
          ),
          children: [
            const TextSpan(
              text: 'Guarda notas, fotos y comentarios sobre la evolución, salud y momentos importantes de tu animal. ',
            ),
            TextSpan(
              text: 'Max X notas.',
              style: AppTypography.body4.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.greyNegro,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.l),
    ];

    final grouped = _groupByMonth(entries);

    for (final group in grouped.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Text(
            group.key,
            style: AppTypography.body3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryFrances,
            ),
          ),
        ),
      );

      for (final entry in group.value) {
        children.add(_buildEntryCard(entry));
        children.add(const SizedBox(height: AppSpacing.m));
      }
    }

    children.add(const SizedBox(height: 80));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Map<String, List<DiaryEntryEntity>> _groupByMonth(
    List<DiaryEntryEntity> entries,
  ) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final Map<String, List<DiaryEntryEntity>> grouped = {};

    for (final entry in entries) {
      try {
        final date = DateTime.parse(entry.date);
        final key = '${months[date.month - 1]} ${date.year}';
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(entry);
      } catch (_) {
        grouped.putIfAbsent('Sin fecha', () => []);
        grouped['Sin fecha']!.add(entry);
      }
    }

    return grouped;
  }

  // ── Entry card ───────────────────────────────────────────────

  Widget _buildEntryCard(DiaryEntryEntity entry) {
    String dateDisplay = '';
    try {
      final date = DateTime.parse(entry.date);
      final months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      dateDisplay = '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.medium(),
        border: Border.all(color: AppColors.greyDelineante),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.lock_open_outlined, size: 16, color: AppColors.greyBordes),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.title,
                  style: AppTypography.body3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyNegro,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.greyBordes),
            ],
          ),
          const SizedBox(height: 8),

          // Content preview
          Text(
            entry.content,
            style: AppTypography.body4.copyWith(
              color: AppColors.greyMedio,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // ALL attachments list (clickable to download)
          if (entry.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...entry.attachments.map((att) => _buildAttachmentLink(att, entry)),
          ],

          const SizedBox(height: 10),

          // Date + popup menu row
          Row(
            children: [
              Text(
                dateDisplay,
                style: AppTypography.body5.copyWith(
                  color: AppColors.secondaryCoral,
                ),
              ),
              const Spacer(),
              _buildPopupMenu(entry),
            ],
          ),
        ],
      ),
    );
  }

  // ── Attachment link (clickable) ──────────────────────────────

  Widget _buildAttachmentLink(DiaryAttachmentEntity attachment, DiaryEntryEntity entry) {
    final isImage = attachment.fileType == 'image';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => _handleAttachmentTap(attachment, entry),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(
              isImage ? Icons.attach_file : Icons.graphic_eq,
              size: 16,
              color: AppColors.primaryFrances,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                attachment.fileName,
                style: AppTypography.body5.copyWith(
                  color: AppColors.primaryFrances,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popup menu (Edit / Delete) ───────────────────────────────

  Widget _buildPopupMenu(DiaryEntryEntity entry) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20, color: AppColors.greyBordes),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: AppBorders.medium()),
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          _navigateToEdit(entry);
        } else if (value == 'delete') {
          _confirmDelete(entry);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryIndigo),
              const SizedBox(width: 10),
              Text(
                'Editar',
                style: AppTypography.body4.copyWith(color: AppColors.greyNegro),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppColors.errorRojo),
              const SizedBox(width: 10),
              Text(
                'Eliminar registro',
                style: AppTypography.body4.copyWith(color: AppColors.errorRojo),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
