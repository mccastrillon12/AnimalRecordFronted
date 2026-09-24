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
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/presentation/pages/animal_diary_create_screen.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/core/widgets/media/audio_inline_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_family_icon_box.dart';

class AnimalDiaryScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalDiaryScreen({super.key, required this.animal});

  @override
  State<AnimalDiaryScreen> createState() => _AnimalDiaryScreenState();
}

class _AnimalDiaryScreenState extends State<AnimalDiaryScreen> {
  final _closeIconKey = GlobalKey();
  bool _showSuccessSnackbar = false;
  String _snackbarMessage = 'Nota guardada exitosamente.';
  final Set<String> _expandedEntryIds = {};
  String? _openMenuEntryId;
  String? _playingAttachmentId;

  void _toggleExpand(String entryId) {
    setState(() {
      if (_expandedEntryIds.contains(entryId)) {
        _expandedEntryIds.remove(entryId);
      } else {
        _expandedEntryIds.add(entryId);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<DiaryCubit>().getDiaryEntries(widget.animal.id);
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AnimalDiaryCreateScreen(animal: widget.animal),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      context.read<DiaryCubit>().refreshDiaryEntries(widget.animal.id);
      _showSnackbar('Nota guardada exitosamente.');
    }
  }

  void _navigateToEdit(DiaryEntryEntity entry) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AnimalDiaryCreateScreen(animal: widget.animal, entry: entry),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      context.read<DiaryCubit>().refreshDiaryEntries(widget.animal.id);
      _showSnackbar('Nota guardada exitosamente.');
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
        title: '¿Desea eliminar la nota?',
        description:
            'Al eliminar esta nota, no podrás recuperarla ni volver a verla.',
        confirmLabel: 'Sí',
        cancelLabel: 'No',
        onConfirm: () {
          context.read<DiaryCubit>().deleteDiaryEntry(
            animalId: widget.animal.id,
            entryId: entry.id,
          );
        },
      ),
    );
  }

  void _handleAttachmentTap(
    DiaryAttachmentEntity attachment,
    DiaryEntryEntity entry,
  ) {
    if (attachment.fileType == 'image') {
      final closeIconRect = _globalRect(_closeIconKey);
      showDialog(
        context: context,
        barrierColor: AppColors.overlayBlack,
        useSafeArea: false,
        builder: (_) => ImagePreviewDialog(
          imageUrl: attachment.url,
          closeIconRect: closeIconRect,
        ),
      );
    } else if (attachment.fileType == 'audio') {
      setState(() {
        _playingAttachmentId = attachment.id;
      });
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
              content: CustomSnackBar(message: state.message, isError: true),
            ),
          );
          // Restore to loaded
          context.read<DiaryCubit>().resetToLoaded();
        }
      },
      child: BlocBuilder<DiaryCubit, DiaryState>(
        buildWhen: (previous, current) {
          // Don't rebuild for save-related states — the create screen handles those
          if (current is DiaryEntrySaving ||
              current is DiaryEntrySaved ||
              current is DiaryEntryUpdated) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          final isLoading = state is DiaryInitial || state is DiaryLoading;

          if (isLoading) {
            return Scaffold(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final bool hasEntries =
              state is DiaryLoaded && state.entries.isNotEmpty;

          return Stack(
            children: [
              ModalPageLayout(
                title: 'Diario',
                backgroundColor: AppColors.bgBlancoAntiFlash,
                bottomSafeAreaColor: AppColors.bgBlancoAntiFlash,
                titlePadding: const EdgeInsets.only(top: 96, bottom: 0),
                fixedTitle: true,
                fixedHeaderHeight: hasEntries ? 180 : 120,
                expandFixedBody: !hasEntries,
                fixedHeaderChild: hasEntries
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: AppTypography.body6.copyWith(
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Guarda notas, fotos y comentarios sobre la evolución, salud y momentos importantes de tu animal. ',
                                  ),
                                  TextSpan(
                                    text: 'Max 15 notas.',
                                    style: AppTypography.body5.copyWith(
                                      color: AppColors.greyNegro,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      )
                    : null,
                trailingIcon: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(key: _closeIconKey, Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                bottomChild: hasEntries
                    ? const SizedBox.shrink()
                    : CustomButton(
                        text: '+ Nueva nota',
                        onPressed: _navigateToCreate,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildBody(state),
                ),
              ),

              // FAB for list view
              if (hasEntries)
                Positioned(
                  bottom: AppSpacing.l + MediaQuery.of(context).padding.bottom,
                  right: AppSpacing.l,
                  child: GestureDetector(
                    onTap: _navigateToCreate,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCoral,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryCoral.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
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
                      child: Material(
                        color: Colors.transparent,
                        child: CustomSnackBar(
                          message: _snackbarMessage,
                          onClose: () =>
                              setState(() => _showSuccessSnackbar = false),
                        ),
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
    return Center(
      key: const Key('diary-empty-content'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimalFamilyIconBox(family: widget.animal.family),
          const SizedBox(height: 48),
          SizedBox(
            width: 249,
            child: Column(
              children: [
                Text(
                  'Crea la primer nota en tu diario',
                  style: AppTypography.body3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.body4,
                    children: [
                      const TextSpan(
                        text:
                            'Guarda notas, fotos y comentarios\nsobre la evolución, salud y momentos\nimportantes de tu animal.\n',
                      ),
                      TextSpan(
                        text: 'Max 15 notas.',
                        style: AppTypography.body4.copyWith(
                          fontWeight: FontWeight.w700,
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
    );
  }

  // ── Entries list (grouped by month) ──────────────────────────

  Widget _buildEntriesList(List<DiaryEntryEntity> entries) {
    final List<Widget> children = [const SizedBox(height: 16)];

    final grouped = _groupByMonth(entries);

    for (final group in grouped.entries) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(group.key, style: AppTypography.body3),
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
      dateDisplay =
          '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.medium(),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1925).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 16, right: 24, bottom: 8, left: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final style = AppTypography.body4.copyWith(
            color: AppColors.greyNegro,
            height: 1.5,
          );
          final textPainter = TextPainter(
            text: TextSpan(text: entry.content, style: style),
            maxLines: 4,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: constraints.maxWidth);
          final isTextExceeding = textPainter.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.greyNegro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isTextExceeding)
                    GestureDetector(
                      onTap: () => _toggleExpand(entry.id),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          _expandedEntryIds.contains(entry.id)
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.greyMedio,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Content preview
              Text(
                entry.content,
                style: style,
                maxLines: _expandedEntryIds.contains(entry.id) ? null : 4,
                overflow: _expandedEntryIds.contains(entry.id)
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),

              // ALL attachments list
              if (entry.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...entry.attachments.map(
                  (att) => _buildAttachmentLink(att, entry),
                ),
              ],

              const SizedBox(height: 8),

              // Divider
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.greyDelineante,
              ),

              const SizedBox(height: 8),

              // Date + popup menu row
              Row(
                children: [
                  Text(
                    dateDisplay,
                    style: AppTypography.body5.copyWith(
                      color: AppColors.greyBordes,
                    ),
                  ),
                  const Spacer(),
                  _buildPopupMenu(entry),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Attachment link (clickable) ──────────────────────────────

  Widget _buildAttachmentLink(
    DiaryAttachmentEntity attachment,
    DiaryEntryEntity entry,
  ) {
    final isImage = attachment.fileType == 'image';
    final isPlayingThis =
        attachment.fileType == 'audio' && _playingAttachmentId == attachment.id;

    // ── Inline WhatsApp-style player ──
    if (isPlayingThis) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AudioInlinePlayer(
          key: ValueKey('player_${attachment.id}'),
          audioUrl: attachment.url,
          onCompleted: () {
            if (mounted) {
              setState(() => _playingAttachmentId = null);
            }
          },
        ),
      );
    }

    // ── Default attachment link ──
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _handleAttachmentTap(attachment, entry),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            isImage
                ? SvgPicture.asset(
                    'assets/icons/vuesax-linear-paperclip-2.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryFrances,
                      BlendMode.srcIn,
                    ),
                  )
                : const Icon(
                    Icons.graphic_eq,
                    size: 20,
                    color: AppColors.primaryFrances,
                  ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                attachment.fileName,
                style: AppTypography.body3.copyWith(
                  color: AppColors.primaryFrances,
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
    final isOpen = _openMenuEntryId == entry.id;

    return PopupMenuButton<String>(
      onOpened: () => setState(() => _openMenuEntryId = entry.id),
      onCanceled: () => setState(() => _openMenuEntryId = null),
      padding: EdgeInsets.zero,
      color: AppColors.white,
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 210),
      shape: RoundedRectangleBorder(borderRadius: AppBorders.medium()),
      elevation: 4,
      menuPadding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onSelected: (value) {
        setState(() => _openMenuEntryId = null);
        if (value == 'edit') {
          _navigateToEdit(entry);
        } else if (value == 'delete') {
          _confirmDelete(entry);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 7,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/icon_edit 1.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.greyMedio,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 11),
              Flexible(child: Text('Editar', style: AppTypography.body4)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 7,
            bottom: 24,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/icon_trash.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.errorRojo,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 11),
              Flexible(
                child: Text(
                  'Eliminar registro',
                  style: AppTypography.body4.copyWith(
                    color: AppColors.errorRojo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isOpen ? AppColors.bgBlancoAntiFlash : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.more_horiz,
            size: 24,
            color: isOpen ? AppColors.primaryFrances : const Color(0xFF59667A),
          ),
        ),
      ),
    );
  }
}

Rect? _globalRect(GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}
