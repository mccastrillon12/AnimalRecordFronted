import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class AudioPlayerWidget extends StatefulWidget {
  final List<String> audioUrls;
  final List<String> fileNames;
  final int initialIndex;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrls,
    required this.fileNames,
    this.initialIndex = 0,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _audioPlayer;
  late int _currentIndex;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        await _audioPlayer.play(UrlSource(widget.audioUrls[_currentIndex]));
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _skipPrevious() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isLoading = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.audioUrls[_currentIndex]));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipNext() async {
    if (_currentIndex < widget.audioUrls.length - 1) {
      setState(() {
        _currentIndex++;
        _isLoading = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.audioUrls[_currentIndex]));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nombre del archivo
          Text(
            widget.fileNames[_currentIndex],
            style: AppTypography.body4.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Barra de progreso y tiempos
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: AppTypography.body6.copyWith(color: Colors.white70),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    value: _position.inSeconds.toDouble().clamp(
                          0,
                          _duration.inSeconds.toDouble() > 0
                              ? _duration.inSeconds.toDouble()
                              : 1.0,
                        ),
                    onChanged: (value) async {
                      final position = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(position);
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: AppTypography.body6.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Controles de reproducción
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio anterior
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: _currentIndex > 0 ? Colors.white : Colors.white38,
                  size: 40,
                ),
                onPressed: _currentIndex > 0 && !_isLoading ? _skipPrevious : null,
              ),
              const SizedBox(width: 24),
              // Play/Pausa
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 44,
                        ),
                ),
              ),
              const SizedBox(width: 24),
              // Audio siguiente
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: _currentIndex < widget.audioUrls.length - 1 ? Colors.white : Colors.white38,
                  size: 40,
                ),
                onPressed: _currentIndex < widget.audioUrls.length - 1 && !_isLoading ? _skipNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
