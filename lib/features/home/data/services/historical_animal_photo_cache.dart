import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/repositories/historical_animal_photo_store.dart';
import 'package:animal_record/core/cache/bounded_memory_cache.dart';

/// Published photos are immutable. Cache by account and publication, never URL.
class HistoricalAnimalPhotoCache implements HistoricalAnimalPhotoStore {
  final Future<String?> Function() readAccountId;
  final Future<Directory> Function() cacheDirectory;
  final BoundedMemoryCache<String, Uint8List> _memory;
  final int maxDiskBytes;
  final _pending = <String, Future<Uint8List>>{};
  int _generation = 0;
  String? _accountId;

  HistoricalAnimalPhotoCache({
    required this.readAccountId,
    Future<Directory> Function()? cacheDirectory,
    int maxMemoryBytes = 16 * 1024 * 1024,
    this.maxDiskBytes = 128 * 1024 * 1024,
  }) : cacheDirectory = cacheDirectory ?? getTemporaryDirectory,
       _memory = BoundedMemoryCache(
         maxEntries: 32,
         maxBytes: maxMemoryBytes,
         sizeOf: (bytes) => bytes.lengthInBytes,
       );

  @override
  void clearMemory() {
    ++_generation;
    _memory.clear();
    _pending.clear();
    _accountId = null;
  }

  @override
  Uint8List? peek(HistoricalFileReference photo) =>
      _accountId == null ? null : _memory[_key(_accountId!, photo)];

  String _key(String accountId, HistoricalFileReference photo) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            accountId,
            photo.periodId,
            photo.publicationHash,
            photo.entryId,
            photo.fileId,
          ]),
        ),
      )
      .toString();

  @override
  Future<Uint8List> load(
    HistoricalFileReference photo,
    Future<List<int>> Function() download,
  ) async {
    final generation = _generation;
    final accountId = await readAccountId();
    _checkSession(generation);
    if (accountId == null || accountId.isEmpty) {
      return _download(download);
    }
    _accountId = accountId;
    final key = _key(accountId, photo);
    final memory = _memory[key];
    if (memory != null) {
      return memory;
    }
    final pending = _pending[key];
    if (pending != null) return pending;
    final request = _load(key, generation, download);
    _pending[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_pending[key], request)) _pending.remove(key);
    }
  }

  Future<Uint8List> _load(
    String key,
    int generation,
    Future<List<int>> Function() download,
  ) async {
    File? file;
    Uint8List? bytes;
    try {
      final root = await cacheDirectory();
      final directory = Directory('${root.path}/historical_animal_photos_v1');
      await directory.create(recursive: true);
      file = File('${directory.path}/$key.image');
      if (await file.exists()) {
        bytes = await file.readAsBytes();
        await _validate(bytes);
      }
    } catch (_) {
      // Cache failure must not prevent downloading a valid photo.
      bytes = null;
    }
    _checkSession(generation);
    if (bytes == null) {
      bytes = await _download(download);
      _checkSession(generation);
      if (file != null) {
        try {
          // Only complete, decodable images enter the disk cache.
          final temporary = File('${file.path}.part');
          await temporary.writeAsBytes(bytes, flush: true);
          await temporary.rename(file.path);
          await _trimDisk(file.parent);
        } catch (_) {
          // Keep the successful photo available even if disk space is exhausted.
        }
      }
    }
    _checkSession(generation);
    _memory[key] = bytes;
    return bytes;
  }

  Future<Uint8List> _download(Future<List<int>> Function() download) async {
    final bytes = Uint8List.fromList(await download());
    await _validate(bytes);
    return bytes;
  }

  Future<void> _validate(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  }

  Future<void> _trimDisk(Directory directory) async {
    final files = await directory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.image'))
        .cast<File>()
        .toList();
    final dated = [
      for (final file in files) (file: file, stat: await file.stat()),
    ];
    dated.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    var bytes = dated.fold<int>(0, (sum, entry) => sum + entry.stat.size);
    var count = dated.length;
    for (final entry in dated) {
      if (count <= 200 && bytes <= maxDiskBytes) break;
      await entry.file.delete();
      bytes -= entry.stat.size;
      count--;
    }
  }

  void _checkSession(int generation) {
    if (generation != _generation) throw StateError('La sesión cambió.');
  }
}
