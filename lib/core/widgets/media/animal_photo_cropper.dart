import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';

const double animalPhotoAspectRatio = 2;

Future<String?> showAnimalPhotoCropper(
  BuildContext context, {
  required String imagePath,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AnimalPhotoCropper(imagePath: imagePath),
    ),
  );
}

class AnimalPhotoCropper extends StatefulWidget {
  final String imagePath;

  const AnimalPhotoCropper({super.key, required this.imagePath});

  @override
  State<AnimalPhotoCropper> createState() => _AnimalPhotoCropperState();
}

class _AnimalPhotoCropperState extends State<AnimalPhotoCropper> {
  static const double _maxZoom = 4;
  static const int _outputWidth = 1600;
  static const int _outputHeight = 800;

  ui.Image? _image;
  Object? _loadError;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _gestureStartZoom = 1;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocalPoint = Offset.zero;
  Size _viewportSize = Size.zero;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  double _baseScale(Size viewport) {
    final image = _image!;
    return math.max(
      viewport.width / image.width,
      viewport.height / image.height,
    );
  }

  Offset _clampOffset(Offset value, double zoom, Size viewport) {
    if (_image == null || viewport.isEmpty) return Offset.zero;
    final scale = _baseScale(viewport) * zoom;
    final maxX = math.max(0.0, (_image!.width * scale - viewport.width) / 2);
    final maxY = math.max(0.0, (_image!.height * scale - viewport.height) / 2);
    return Offset(value.dx.clamp(-maxX, maxX), value.dy.clamp(-maxY, maxY));
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
    _gestureStartOffset = _offset;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final nextZoom = (_gestureStartZoom * details.scale).clamp(1.0, _maxZoom);
    final center = _viewportSize.center(Offset.zero);
    final scaleChange = nextZoom / _gestureStartZoom;
    final nextOffset =
        details.localFocalPoint -
        center -
        (_gestureStartFocalPoint - center - _gestureStartOffset) * scaleChange;

    setState(() {
      _zoom = nextZoom;
      _offset = _clampOffset(nextOffset, nextZoom, _viewportSize);
    });
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value;
      _offset = _clampOffset(_offset, value, _viewportSize);
    });
  }

  Future<void> _saveCrop() async {
    if (_image == null || _viewportSize.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const outputSize = Size(1600, 800);
      final outputMultiplier = outputSize.width / _viewportSize.width;
      final displayScale = _baseScale(_viewportSize) * _zoom;
      final displaySize = Size(
        _image!.width * displayScale,
        _image!.height * displayScale,
      );
      final displayTopLeft =
          _viewportSize.center(Offset.zero) -
          displaySize.center(Offset.zero) +
          _offset;
      final outputRect = Rect.fromLTWH(
        displayTopLeft.dx * outputMultiplier,
        displayTopLeft.dy * outputMultiplier,
        displaySize.width * outputMultiplier,
        displaySize.height * outputMultiplier,
      );

      canvas.drawImageRect(
        _image!,
        Rect.fromLTWH(
          0,
          0,
          _image!.width.toDouble(),
          _image!.height.toDouble(),
        ),
        outputRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      final croppedImage = await recorder.endRecording().toImage(
        _outputWidth,
        _outputHeight,
      );
      final data = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();
      if (data == null) throw StateError('No se pudo generar el recorte.');

      final directory = await getTemporaryDirectory();
      final outputFile = File(
        '${directory.path}${Platform.pathSeparator}'
        'animal_photo_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await outputFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );

      if (mounted) Navigator.of(context).pop(outputFile.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible guardar el recorte.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101318),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101318),
        foregroundColor: Colors.white,
        title: const Text('Ajustar foto'),
        actions: [
          TextButton(
            key: const Key('animal-photo-crop-save'),
            onPressed: _image == null || _isSaving ? null : _saveCrop,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Text(
            'No fue posible abrir esta imagen.',
            style: AppTypography.body3.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = AppSpacing.m * 2;
                var width = constraints.maxWidth - horizontalPadding;
                var height = width / animalPhotoAspectRatio;
                final maxHeight = constraints.maxHeight - AppSpacing.xl;
                if (height > maxHeight) {
                  height = maxHeight;
                  width = height * animalPhotoAspectRatio;
                }
                final size = Size(width, height);
                if (_viewportSize != size) {
                  _viewportSize = size;
                  _offset = _clampOffset(_offset, _zoom, size);
                }

                return GestureDetector(
                  key: const Key('animal-photo-crop-viewport'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: ClipRect(
                    child: CustomPaint(
                      size: size,
                      painter: _CropImagePainter(
                        image: _image!,
                        zoom: _zoom,
                        offset: _offset,
                      ),
                      foregroundPainter: const _CropGridPainter(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: Column(
            children: [
              Text(
                'Mueve y amplía la foto para llenar el encuadre',
                style: AppTypography.body4.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  const Icon(
                    Icons.photo_size_select_small,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Slider(
                      key: const Key('animal-photo-crop-zoom'),
                      min: 1,
                      max: _maxZoom,
                      value: _zoom,
                      activeColor: AppColors.primaryFrances,
                      onChanged: _setZoom,
                    ),
                  ),
                  const Icon(
                    Icons.photo_size_select_large,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropImagePainter extends CustomPainter {
  final ui.Image image;
  final double zoom;
  final Offset offset;

  const _CropImagePainter({
    required this.image,
    required this.zoom,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseScale = math.max(
      size.width / image.width,
      size.height / image.height,
    );
    final displaySize = Size(
      image.width * baseScale * zoom,
      image.height * baseScale * zoom,
    );
    final topLeft =
        size.center(Offset.zero) - displaySize.center(Offset.zero) + offset;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      topLeft & displaySize,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _CropImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset;
  }
}

class _CropGridPainter extends CustomPainter {
  const _CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var index = 1; index < 3; index++) {
      final dx = size.width * index / 3;
      final dy = size.height * index / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
