import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/widgets/feedback/custom_snackbar.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Represents an attachment in the diary entry.
class DiaryAttachment {
  final String name;
  final String path;
  final DiaryAttachmentType type;
  final int sizeBytes;
  final DateTime createdAt;
  final Duration? audioDuration;
  final String? remoteUrl; // for edit mode existing attachments
  final String? id; // for edit mode existing attachments

  DiaryAttachment({
    required this.name,
    required this.path,
    required this.type,
    required this.sizeBytes,
    required this.createdAt,
    this.audioDuration,
    this.remoteUrl,
    this.id,
  });

  String get sizeDisplay {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} Kb';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mb';
  }

  String get timeDisplay {
    final now = DateTime.now();
    final isToday = now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;

    final hour = createdAt.hour > 12 ? createdAt.hour - 12 : createdAt.hour;
    final amPm = createdAt.hour >= 12 ? 'p.m.' : 'a.m.';
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $amPm';

    return isToday ? 'Hoy $timeStr' : timeStr;
  }

  String get durationDisplay {
    if (audioDuration == null) return '';
    final minutes = audioDuration!.inMinutes;
    final seconds = (audioDuration!.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

enum DiaryAttachmentType { image, audio }

class AnimalDiaryCreateScreen extends StatefulWidget {
  final AnimalModel animal;
  final DiaryEntryEntity? entry;

  const AnimalDiaryCreateScreen({
    super.key,
    required this.animal,
    this.entry,
  });

  @override
  State<AnimalDiaryCreateScreen> createState() => _AnimalDiaryCreateScreenState();
}

class _AnimalDiaryCreateScreenState extends State<AnimalDiaryCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool get _isEditMode => widget.entry != null;

  final List<DiaryAttachment> _attachments = [];
  final List<String> _deletedAttachmentIds = [];
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _isSaving = false;

  String get _formattedDate {
    final now = DateTime.now();
    final weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];

    return '$weekday, ${now.day} de $month';
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      
      // Parse existing attachments to show in the list
      // They are already uploaded, so we set a flag or just show them.
      for (final att in widget.entry!.attachments) {
        _attachments.add(DiaryAttachment(
          name: att.fileName,
          path: '', // empty path means it's remote
          type: att.fileType == 'image' ? DiaryAttachmentType.image : DiaryAttachmentType.audio,
          sizeBytes: att.size,
          createdAt: DateTime.now(), // or parse if available
          remoteUrl: att.url,
          id: att.id,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── Image from gallery ────────────────────────────────────────
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        final size = await file.length();
        setState(() {
          _attachments.add(DiaryAttachment(
            name: image.name,
            path: image.path,
            type: DiaryAttachmentType.image,
            sizeBytes: size,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (_) {}
  }

  // ── Image from camera ─────────────────────────────────────────
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        final size = await file.length();
        setState(() {
          _attachments.add(DiaryAttachment(
            name: image.name,
            path: image.path,
            type: DiaryAttachmentType.image,
            sizeBytes: size,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (_) {}
  }

  // ── Audio recording ───────────────────────────────────────────
  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${dir.path}/diary_audio_$timestamp.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        _recordingSeconds = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _recordingSeconds++);
        });

        setState(() => _isRecording = true);
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        final size = await file.length();
        // Extract timestamp from the path to use in the name
        final timestamp = path.split('_').last.replaceAll('.m4a', '');
        setState(() {
          _isRecording = false;
          _attachments.add(DiaryAttachment(
            name: 'Audio_$timestamp.m4a',
            path: path,
            type: DiaryAttachmentType.audio,
            sizeBytes: size,
            createdAt: DateTime.now(),
            audioDuration: Duration(seconds: _recordingSeconds),
          ));
          _recordingSeconds = 0;
        });
      } else {
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
        });
      }
    } catch (_) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      final attachment = _attachments[index];
      if (attachment.id != null) {
        _deletedAttachmentIds.add(attachment.id!);
      }
      _attachments.removeAt(index);
    });
  }

  void _saveDiaryEntry() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) return;

    // Filter out existing attachments because they are already uploaded
    final localAttachments = _attachments.where((a) => a.remoteUrl == null).map((a) {
      return LocalAttachment(
        path: a.path,
        fileName: a.name,
        mimeType: a.type == DiaryAttachmentType.image
            ? 'image/jpeg'
            : 'audio/mp4',
        fileType: a.type == DiaryAttachmentType.image ? 'image' : 'audio',
        size: a.sizeBytes,
      );
    }).toList();

    if (_isEditMode) {
      context.read<DiaryCubit>().updateDiaryEntry(
        animalId: widget.animal.id,
        entryId: widget.entry!.id,
        title: title,
        content: content,
        newAttachments: localAttachments,
        deletedAttachmentIds: _deletedAttachmentIds,
      );
    } else {
      context.read<DiaryCubit>().createDiaryEntry(
        animalId: widget.animal.id,
        title: title,
        content: content,
        date: DateTime.now().toUtc().toIso8601String(),
        attachments: localAttachments,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiaryCubit, DiaryState>(
      listener: (context, state) {
        if (state is DiaryEntrySaving) {
          setState(() => _isSaving = true);
        } else if (state is DiaryEntrySaved || state is DiaryEntryUpdated) {
          setState(() => _isSaving = false);
          // Pop back to diary list — it will re-fetch on init
          Navigator.of(context).pop(true);
        } else if (state is DiaryError) {
          setState(() => _isSaving = false);
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
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ModalPageLayout(
      title: _formattedDate,
      headerChildren: [
        // ── Save button (top-left) ─────────────────────────────
        Positioned(
          top: 32,
          left: 24,
          child: GestureDetector(
            onTap: _isSaving ? null : _saveDiaryEntry,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.bookmark_border, color: AppColors.primaryIndigo, size: 20),
                const SizedBox(width: 4),
                Text(
                  _isSaving ? 'Guardando...' : 'Guardar',
                  style: AppTypography.body4.copyWith(
                    color: _isSaving ? AppColors.greyMedio : AppColors.primaryIndigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Bottom toolbar ──────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.greyBlanco,
              border: Border(
                top: BorderSide(color: AppColors.greyDelineante, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarTextIcon('Aa'),
                _buildToolbarIcon(
                  Icons.image_outlined,
                  onTap: _pickImageFromGallery,
                ),
                _buildToolbarIcon(
                  Icons.camera_alt_outlined,
                  onTap: _pickImageFromCamera,
                ),
                _buildToolbarIcon(
                  Icons.graphic_eq,
                  onTap: _toggleAudioRecording,
                  isActive: _isRecording,
                ),
              ],
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Recording indicator ─────────────────────────────
            if (_isRecording)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorRojo.withValues(alpha: 0.08),
                  borderRadius: AppBorders.medium(),
                  border: Border.all(
                    color: AppColors.errorRojo.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.errorRojo,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Grabando audio...',
                      style: AppTypography.body4.copyWith(
                        color: AppColors.errorRojo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.errorRojo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.errorRojo,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Lock icon ───────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppBorders.medium(),
                  border: Border.all(color: AppColors.greyDelineante),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_open_outlined,
                  color: AppColors.primaryIndigo,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // ── Title field ─────────────────────────────────────
            Text(
              'Título',
              style: AppTypography.body5.copyWith(color: AppColors.greyNegro),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.greyDelineante),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.greyDelineante),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.primaryIndigo),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // ── Content field ───────────────────────────────────
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                hintText: 'Empieza a escribir aquí...',
                hintStyle: AppTypography.body4.copyWith(
                  color: AppColors.greyMedio,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.greyDelineante),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.greyDelineante),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorders.small(),
                  borderSide: const BorderSide(color: AppColors.primaryIndigo),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            // ── Attachments section ─────────────────────────────
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.l),
              Text(
                'Adjuntos',
                style: AppTypography.body3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyNegro,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ..._attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;
                return _buildAttachmentRow(attachment, index);
              }),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Attachment row widget ──────────────────────────────────────
  Widget _buildAttachmentRow(DiaryAttachment attachment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppBorders.medium(),
        border: Border.all(color: AppColors.greyDelineante),
      ),
      child: Row(
        children: [
          // Thumbnail or audio icon
          if (attachment.type == DiaryAttachmentType.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: attachment.remoteUrl != null
                  ? CachedNetworkImage(
                      imageUrl: attachment.remoteUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.greyDelineante,
                        child: const Icon(Icons.image, color: AppColors.greyBordes),
                      ),
                    )
                  : Image.file(
                      File(attachment.path),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.greyDelineante,
                        child: const Icon(Icons.image, color: AppColors.greyBordes),
                      ),
                    ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: AppColors.primaryIndigo,
                size: 24,
              ),
            ),

          const SizedBox(width: 12),

          // Name + metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: AppTypography.body4.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyNegro,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (attachment.type == DiaryAttachmentType.audio &&
                        attachment.audioDuration != null) ...[
                      Text(
                        attachment.durationDisplay,
                        style: AppTypography.body5.copyWith(
                          color: AppColors.primaryFrances,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Text(
                        attachment.sizeDisplay,
                        style: AppTypography.body5.copyWith(
                          color: AppColors.greyMedio,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      attachment.timeDisplay,
                      style: AppTypography.body5.copyWith(
                        color: AppColors.greyMedio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          GestureDetector(
            onTap: () => _removeAttachment(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.secondaryCoral,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toolbar builders ───────────────────────────────────────────

  Widget _buildToolbarTextIcon(String data) {
    return IconButton(
      onPressed: () {},
      icon: Text(
        data,
        style: AppTypography.body3.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryIndigo,
        ),
      ),
    );
  }

  Widget _buildToolbarIcon(
    IconData icon, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isActive ? AppColors.errorRojo : AppColors.primaryIndigo,
        size: 24,
      ),
    );
  }
}
