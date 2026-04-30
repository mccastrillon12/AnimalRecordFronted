import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/core/widgets/feedback/custom_snackbar.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_cubit.dart';
import 'package:animal_record/features/diary/presentation/cubit/diary_state.dart';
import 'package:animal_record/features/diary/domain/entities/diary_entry_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animal_record/core/widgets/media/image_preview_dialog.dart';
import 'package:animal_record/core/widgets/media/audio_inline_player.dart';

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
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(0)} Kb';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mb';
  }

  String get timeDisplay {
    final now = DateTime.now();
    final isToday =
        now.year == createdAt.year &&
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

  const AnimalDiaryCreateScreen({super.key, required this.animal, this.entry});

  @override
  State<AnimalDiaryCreateScreen> createState() =>
      _AnimalDiaryCreateScreenState();
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
  Timer? _amplitudeTimer;
  List<double> _liveAmplitudes = [];
  bool _isSaving = false;

  // Recorded audio preview (toolbar overlay after recording)
  String? _recordedPreviewPath;
  int _recordedPreviewSeconds = 0;
  AudioPlayer? _previewPlayer;
  bool _previewPlaying = false;
  Duration _previewPosition = Duration.zero;
  Duration _previewDuration = Duration.zero;

  int? _playingAttachmentIndex;

  static const int _maxAttachments = 5;
  static const int _maxAudioSeconds = 60;

  int get _attachmentCount => _attachments.length;

  String get _formattedDate {
    final now = DateTime.now();
    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
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
        _attachments.add(
          DiaryAttachment(
            name: att.fileName,
            path: '', // empty path means it's remote
            type: att.fileType == 'image'
                ? DiaryAttachmentType.image
                : DiaryAttachmentType.audio,
            sizeBytes: att.size,
            createdAt: DateTime.now(), // or parse if available
            remoteUrl: att.url,
            id: att.id,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _previewPlayer?.dispose();
    super.dispose();
  }

  // ── Image from gallery ────────────────────────────────────────
  Future<void> _pickImageFromGallery() async {
    if (_attachmentCount >= _maxAttachments) {
      _showLimitMessage(
        'Solo puedes adjuntar $_maxAttachments archivos en total.',
      );
      return;
    }
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
          _attachments.add(
            DiaryAttachment(
              name: image.name,
              path: image.path,
              type: DiaryAttachmentType.image,
              sizeBytes: size,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (_) {}
  }

  // ── Image from camera ─────────────────────────────────────────
  Future<void> _pickImageFromCamera() async {
    if (_attachmentCount >= _maxAttachments) {
      _showLimitMessage(
        'Solo puedes adjuntar $_maxAttachments archivos en total.',
      );
      return;
    }
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
          _attachments.add(
            DiaryAttachment(
              name: image.name,
              path: image.path,
              type: DiaryAttachmentType.image,
              sizeBytes: size,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (_) {}
  }

  // ── Audio recording ───────────────────────────────────────────
  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
        _liveAmplitudes.clear();
      });
    }
  }

  Future<void> _startRecording() async {
    if (_attachmentCount >= _maxAttachments) {
      _showLimitMessage(
        'Solo puedes adjuntar $_maxAttachments archivos en total.',
      );
      return;
    }
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
        _liveAmplitudes.clear();
        
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _recordingSeconds++);
          if (_recordingSeconds >= _maxAudioSeconds) {
            _stopRecording();
            _showLimitMessage(
              'La grabación de audio tiene un límite de 1 minuto.',
            );
          }
        });

        _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
          if (await _audioRecorder.isRecording()) {
            final amp = await _audioRecorder.getAmplitude();
            // Map roughly from -50dB..0dB to 0.0..1.0
            double val = ((amp.current + 50) / 50).clamp(0.0, 1.0);
            if (mounted) {
              setState(() {
                _liveAmplitudes.add(val);
                if (_liveAmplitudes.length > 40) {
                  _liveAmplitudes.removeAt(0);
                }
              });
            }
          }
        });

        setState(() => _isRecording = true);
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    final seconds = _recordingSeconds;
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedPreviewPath = path;
          _recordedPreviewSeconds = seconds;
          _recordingSeconds = 0;
        });
        // Start preview playback setup
        _initPreviewPlayer(path, Duration(seconds: seconds));
      } else {
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
          _liveAmplitudes.clear();
        });
      }
    } catch (_) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
        _liveAmplitudes.clear();
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

  void _showLimitMessage(String message) {
    if (!mounted) return;
    ErrorDisplay.showError(context, message);
  }

  void _saveDiaryEntry() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) return;

    // Filter out existing attachments because they are already uploaded
    final localAttachments = _attachments.where((a) => a.remoteUrl == null).map(
      (a) {
        return LocalAttachment(
          path: a.path,
          fileName: a.name,
          mimeType: a.type == DiaryAttachmentType.image
              ? 'image/jpeg'
              : 'audio/mp4',
          fileType: a.type == DiaryAttachmentType.image ? 'image' : 'audio',
          size: a.sizeBytes,
        );
      },
    ).toList();

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
              content: CustomSnackBar(message: state.message, isError: true),
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
            child: SizedBox(
              height: 48, // Matches the default 48px height of the IconButton on the right side
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.bookmark_border,
                      color: AppColors.primaryIndigo,
                      size: 20,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    _isSaving ? 'Guardando...' : 'Guardar',
                    style: AppTypography.body4.copyWith(
                      color: _isSaving
                          ? AppColors.greyMedio
                          : AppColors.primaryIndigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Bottom toolbar + recording overlay ──────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: (_isRecording || _recordedPreviewPath != null)
              ? _buildAudioOverlay()
              : _buildToolbar(),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: AppTypography.body4.copyWith(
                color: AppColors.greyNegro,
                height: 1.5,
              ),
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
              style: AppTypography.body4.copyWith(
                color: AppColors.greyNegro,
                height: 1.5,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                hintText: 'Empieza a escribir aquí...',
                hintStyle: AppTypography.body4.copyWith(
                  color: AppColors.greyTextos,
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

  // ── Recorded preview helpers ──────────────────────────────────

  void _initPreviewPlayer(String path, Duration duration) {
    _previewPlayer?.dispose();
    final player = AudioPlayer();
    _previewPlayer = player;
    _previewPosition = Duration.zero;
    _previewDuration = duration;

    player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _previewPlaying = s == PlayerState.playing);
      if (s == PlayerState.completed) {
        setState(() {
          _previewPlaying = false;
          _previewPosition = Duration.zero;
        });
      }
    });
    player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _previewDuration = d);
    });
    player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
  }

  Future<void> _togglePreviewPlayback() async {
    if (_recordedPreviewPath == null) return;
    if (_previewPlaying) {
      await _previewPlayer?.pause();
    } else {
      await _previewPlayer?.play(DeviceFileSource(_recordedPreviewPath!));
    }
  }

  void _confirmRecordedPreview() {
    if (_recordedPreviewPath == null) return;
    final path = _recordedPreviewPath!;
    final seconds = _recordedPreviewSeconds;
    final timestamp = path.split('_').last.replaceAll('.m4a', '');
    final file = File(path);

    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;

    file.length().then((size) {
      if (mounted) {
        setState(() {
          _attachments.add(
            DiaryAttachment(
              name: 'Audio_$timestamp.m4a',
              path: path,
              type: DiaryAttachmentType.audio,
              sizeBytes: size,
              createdAt: DateTime.now(),
              audioDuration: Duration(seconds: seconds),
            ),
          );
          _recordedPreviewPath = null;
          _recordedPreviewSeconds = 0;
          _previewPlaying = false;
          _previewPosition = Duration.zero;
          _previewDuration = Duration.zero;
        });
      }
    });
  }

  void _discardRecordedPreview() {
    if (_recordedPreviewPath == null) return;
    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;
    final file = File(_recordedPreviewPath!);
    if (file.existsSync()) file.deleteSync();
    setState(() {
      _recordedPreviewPath = null;
      _recordedPreviewSeconds = 0;
      _previewPlaying = false;
      _previewPosition = Duration.zero;
      _previewDuration = Duration.zero;
    });
  }

  List<double> _generateBars(String seed) {
    final rng = Random(seed.hashCode);
    return List.generate(40, (_) => 0.15 + rng.nextDouble() * 0.85);
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Attachment row widget (original design) ────────────────────
  Widget _buildAttachmentRow(DiaryAttachment attachment, int index) {
    final isImage = attachment.type == DiaryAttachmentType.image;
    final isPlayingThis = !isImage && _playingAttachmentIndex == index;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              if (isImage) ...[
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ImagePreviewDialog(
                        imageUrl: attachment.remoteUrl ?? attachment.path,
                      ),
                    );
                  },
                  child: ClipRRect(
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
                              child: const Icon(
                                Icons.image,
                                color: AppColors.greyBordes,
                              ),
                            ),
                          )
                        : Image.file(
                            File(attachment.path),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.greyDelineante,
                                  child: const Icon(
                                    Icons.image,
                                    color: AppColors.greyBordes,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: isPlayingThis
                    ? AudioInlinePlayer(
                        key: ValueKey('player_create_$index'),
                        audioUrl: attachment.remoteUrl ?? attachment.path,
                        onCompleted: () {
                          if (mounted) setState(() => _playingAttachmentIndex = null);
                        },
                      )
                    : GestureDetector(
                        onTap: () {
                          if (isImage) {
                            showDialog(
                              context: context,
                              builder: (_) => ImagePreviewDialog(
                                imageUrl: attachment.remoteUrl ?? attachment.path,
                              ),
                            );
                          } else {
                            setState(() => _playingAttachmentIndex = index);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Text(
                      attachment.name,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.greyNegro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (!isImage && attachment.audioDuration != null) ...[
                          Text(
                            attachment.durationDisplay,
                            style: AppTypography.body6.copyWith(
                              color: AppColors.primaryFrances,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryFrances,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          Text(
                            attachment.sizeDisplay,
                            style: AppTypography.body6.copyWith(
                              color: AppColors.greyMedio,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          attachment.timeDisplay,
                          style: AppTypography.body6.copyWith(
                            color: AppColors.greyMedio,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), // closes Column
              ), // closes GestureDetector
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _removeAttachment(index),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppColors.secondaryCoral,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.greyDelineante,
        ),
      ],
    );
  }

  // ── Toolbar builders ───────────────────────────────────────────

  Widget _buildToolbar() {
    return Container(
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
          _buildToolbarIcon(Icons.image_outlined, onTap: _pickImageFromGallery),
          _buildToolbarIcon(
            Icons.camera_alt_outlined,
            onTap: _pickImageFromCamera,
          ),
          _buildToolbarIcon(Icons.graphic_eq, onTap: _startRecording),
        ],
      ),
    );
  }

  Widget _buildAudioOverlay() {
    final isPreview = !_isRecording && _recordedPreviewPath != null;
    
    List<double> bars;
    if (_isRecording) {
      bars = List.filled(40, 0.0);
      final startIndex = 40 - _liveAmplitudes.length;
      for (int i = 0; i < _liveAmplitudes.length; i++) {
        bars[startIndex + i] = _liveAmplitudes[i];
      }
    } else {
      bars = _generateBars(_recordedPreviewPath ?? 'recording');
    }

    final progress = isPreview && _previewDuration.inMilliseconds > 0
        ? _previewPosition.inMilliseconds / _previewDuration.inMilliseconds
        : 0.0;
    final timeStr = _isRecording
        ? '${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}'
        : _fmtDuration(_previewPlaying ? _previewPosition : _previewDuration);

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.greyBlanco,
        border: Border(
          top: BorderSide(color: AppColors.greyDelineante, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Trash — cancel/discard
          GestureDetector(
            onTap: _isRecording ? _cancelRecording : _discardRecordedPreview,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.errorRojo,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Red dot (recording) or nothing (preview)
          if (_isRecording) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.errorRojo,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Time
          Text(
            timeStr,
            style: AppTypography.body6.copyWith(
              color: _isRecording ? AppColors.errorRojo : AppColors.greyMedio,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          // Waveform
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 22),
              painter: _AudioWaveformPainter(
                bars: bars,
                progress: progress, // for recording it's 0.0
                activeColor: AppColors.primaryIndigo,
                inactiveColor: AppColors.greyBordes.withValues(alpha: 0.35),
                isRecording: _isRecording,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pause/Play — stop recording or toggle preview
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _togglePreviewPlayback,
            child: Icon(
              _isRecording
                  ? Icons.pause
                  : (_previewPlaying ? Icons.pause : Icons.play_arrow),
              color: AppColors.greyNegro,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          // Green send/confirm button
          GestureDetector(
            onTap: _isRecording
                ? () async {
                    await _stopRecording();
                    // Small delay for state to settle then auto-confirm
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted && _recordedPreviewPath != null) {
                        _confirmRecordedPreview();
                      }
                    });
                  }
                : _confirmRecordedPreview,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryIndigo,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

// ── Waveform painter for audio attachments ───────────────────────
class _AudioWaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isRecording;

  _AudioWaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.isRecording = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final barWidth = size.width / (bars.length * 2 - 1);
    final maxHeight = size.height;
    final progressX = progress * size.width;

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;
    final recordingPaint = Paint()..color = AppColors.greyBordes.withValues(alpha: 0.7);

    for (int i = 0; i < bars.length; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final barHeight = 4.0 + bars[i] * (maxHeight - 4.0);
      final top = (maxHeight - barHeight) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      
      Paint paint;
      if (isRecording) {
        paint = recordingPaint;
      } else {
        paint = x <= progressX ? activePaint : inactivePaint;
      }
      
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWaveformPainter old) =>
      old.progress != progress || old.bars != bars;
}
