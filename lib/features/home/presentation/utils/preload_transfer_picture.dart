import 'dart:async';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/presentation/utils/animal_picture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

Future<void> preloadTransferPicture(TransferItem item) async {
  final url = validAnimalImageUrl(item.animalImageUrl);
  if (url == null) return;
  final stream = CachedNetworkImageProvider(
    url,
    cacheKey: animalImageCacheKey(url, animalId: item.animalId, ownerId: ''),
  ).resolve(ImageConfiguration.empty);
  final ready = Completer<void>();
  final listener = ImageStreamListener(
    (info, _) {
      info.dispose();
      if (!ready.isCompleted) ready.complete();
    },
    onError: (Object _, StackTrace? _) {
      if (!ready.isCompleted) ready.complete();
    },
  );
  stream.addListener(listener);
  try {
    await ready.future.timeout(const Duration(seconds: 15));
  } catch (_) {
    // Keep the normal species fallback; never log a signed image URL.
  } finally {
    stream.removeListener(listener);
  }
}
