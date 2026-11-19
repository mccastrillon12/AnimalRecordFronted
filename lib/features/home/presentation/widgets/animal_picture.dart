import 'package:animal_record/features/home/domain/usecases/load_animal_photo_usecase.dart';
import 'dart:typed_data';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/utils/animal_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimalPicture extends StatefulWidget {
  final AnimalModel animal;
  final double? width;
  final double? height;
  final double iconSize;
  final double? iconHeight;
  final Color? iconColor;
  final ValueChanged<String>? onImageError;
  const AnimalPicture({
    super.key,
    required this.animal,
    this.width,
    this.height,
    required this.iconSize,
    this.iconHeight,
    this.iconColor = AppColors.primaryFrances,
    this.onImageError,
  });
  @override
  State<AnimalPicture> createState() => _AnimalPictureState();
}

class _AnimalPictureState extends State<AnimalPicture> {
  String? _renewedUrl;
  bool _retried = false;
  Future<Uint8List?>? _historicalPhoto;
  Uint8List? _historicalBytes;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(AnimalPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animal.id != widget.animal.id ||
        oldWidget.animal.imageUrl != widget.animal.imageUrl ||
        oldWidget.animal.ownershipHistory != widget.animal.ownershipHistory) {
      _renewedUrl = null;
      _retried = false;
      _initialize();
    }
  }

  void _initialize() {
    final photo = widget.animal.ownershipHistory?.photo;
    _historicalBytes =
        widget.animal.isHistorical &&
            photo != null &&
            di.sl.isRegistered<LoadAnimalPhotoUseCase>()
        ? di.sl<LoadAnimalPhotoUseCase>().cached(photo)
        : null;
    _historicalPhoto = widget.animal.isHistorical && _historicalBytes == null
        ? _loadHistorical()
        : null;
  }

  Future<Uint8List?> _loadHistorical() async {
    final photo = widget.animal.ownershipHistory?.photo;
    if (photo == null || !di.sl.isRegistered<LoadAnimalPhotoUseCase>()) {
      return null;
    }
    try {
      return await di.sl<LoadAnimalPhotoUseCase>()(photo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _renew(String failedUrl) async {
    if (!mounted || _retried) return;
    _retried = true;
    if (widget.onImageError case final callback?) {
      callback(failedUrl);
      return;
    }
    final animal = widget.animal;
    if (animal.isHistorical ||
        animal.ownerId.isEmpty ||
        !di.sl.isRegistered<LoadAnimalPhotoUseCase>()) {
      return;
    }
    try {
      final url = validAnimalImageUrl(
        await di.sl<LoadAnimalPhotoUseCase>().renewCurrentPhoto(animal.id),
      );
      if (mounted && url != null && url != failedUrl) {
        setState(() => _renewedUrl = url);
      }
    } catch (_) {
      /* Signed URLs must never be included in error logs. */
    }
  }

  Widget _icon() => Center(
    child: SvgPicture.asset(
      animalPictureIcon(
        species: widget.animal.species,
        family: widget.animal.family,
        code: widget.animal.code,
      ),
      width: widget.iconSize,
      height: widget.iconHeight ?? widget.iconSize,
      colorFilter: widget.iconColor == null
          ? null
          : ColorFilter.mode(widget.iconColor!, BlendMode.srcIn),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (widget.animal.isHistorical) {
      if (_historicalBytes case final bytes?) return _historicalImage(bytes);
      return FutureBuilder<Uint8List?>(
        future: _historicalPhoto,
        builder: (_, snapshot) =>
            snapshot.data == null ? _icon() : _historicalImage(snapshot.data!),
      );
    }
    final url = validAnimalImageUrl(_renewedUrl ?? widget.animal.imageUrl);
    if (url == null) return _icon();
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: animalImageCacheKey(
        url,
        animalId: widget.animal.id,
        ownerId: widget.animal.ownerId,
      ),
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => _icon(),
      errorWidget: (_, _, _) => _icon(),
      errorListener: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _renew(url);
      }),
      imageBuilder: (_, provider) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _retried = false;
        });
        return Image(
          image: provider,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _icon(),
        );
      },
    );
  }

  Widget _historicalImage(Uint8List bytes) => Image.memory(
    bytes,
    width: widget.width,
    height: widget.height,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => _icon(),
  );
}
