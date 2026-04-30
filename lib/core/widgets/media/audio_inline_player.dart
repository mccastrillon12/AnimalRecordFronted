import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

/// WhatsApp-style inline audio player with waveform visualization.
///
/// Shows a compact horizontal player with play/pause button, interactive
/// waveform bars, and elapsed/total time. Calls [onCompleted] when the
/// audio finishes so the parent can restore the original attachment link.
class AudioInlinePlayer extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onCompleted;

  const AudioInlinePlayer({
    super.key,
    required this.audioUrl,
    this.onCompleted,
  });

  @override
  State<AudioInlinePlayer> createState() => _AudioInlinePlayerState();
}

class _AudioInlinePlayerState extends State<AudioInlinePlayer>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final List<double> _waveformBars;
  late final AnimationController _playPauseController;

  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  static const int _barCount = 40;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveformBars = _generateBars(widget.audioUrl);

    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      setState(() => _isPlaying = playing);

      if (playing) {
        _playPauseController.forward();
      } else {
        _playPauseController.reverse();
      }

      if (state == PlayerState.completed) {
        setState(() => _position = _duration);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onCompleted?.call();
        });
      }
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _startPlayback();
  }

  Future<void> _startPlayback() async {
    try {
      setState(() => _isLoading = true);
      final source = widget.audioUrl.startsWith('http') || widget.audioUrl.startsWith('https')
          ? UrlSource(widget.audioUrl)
          : DeviceFileSource(widget.audioUrl);
      await _player.play(source);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onCompleted?.call();
      }
    }
  }

  /// Generate deterministic pseudo-random bar heights from URL hash.
  List<double> _generateBars(String url) {
    final rng = Random(url.hashCode);
    return List.generate(_barCount, (_) => 0.15 + rng.nextDouble() * 0.85);
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void _seekToFraction(double fraction) {
    if (_duration == Duration.zero) return;
    final target = Duration(
      milliseconds: (fraction * _duration.inMilliseconds).round(),
    );
    _player.seek(target);
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    _playPauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Play / Pause button (same size as the link icon) ──
        _buildPlayButton(),
        const SizedBox(width: 4),

        // ── Waveform ──
        Expanded(
          child: _WaveformBar(
            bars: _waveformBars,
            progress: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
            activeColor: AppColors.primaryFrances,
            inactiveColor: AppColors.greyBordes.withValues(alpha: 0.4),
            onSeek: _seekToFraction,
          ),
        ),
        const SizedBox(width: 6),

        // ── Time ──
        Text(
          '${_formatTime(_position)} / ${_formatTime(_duration)}',
          style: AppTypography.body6.copyWith(
            color: AppColors.greyMedio,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppColors.primaryFrances,
                strokeWidth: 2,
              ),
            )
          : AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _playPauseController,
              color: AppColors.primaryFrances,
              size: 16,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waveform painter — interactive bar visualization
// ─────────────────────────────────────────────────────────────────────────────

class _WaveformBar extends StatelessWidget {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double>? onSeek;

  const _WaveformBar({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.onSeek,
  });

  void _handleInteraction(Offset localPosition, double width) {
    final fraction = (localPosition.dx / width).clamp(0.0, 1.0);
    onSeek?.call(fraction);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) =>
          _handleInteraction(details.localPosition, context.size?.width ?? 1),
      onHorizontalDragUpdate: (details) =>
          _handleInteraction(details.localPosition, context.size?.width ?? 1),
      child: CustomPaint(
        size: const Size(double.infinity, 16),
        painter: _WaveformPainter(
          bars: bars,
          progress: progress,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final barWidth = size.width / (bars.length * 2 - 1);
    final maxHeight = size.height;
    final progressX = progress * size.width;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round;
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < bars.length; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final barHeight = max(4.0, bars[i] * maxHeight);
      final top = (maxHeight - barHeight) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, x <= progressX ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}
