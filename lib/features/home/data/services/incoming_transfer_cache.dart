import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'dart:convert';
import 'package:animal_record/core/cache/bounded_memory_cache.dart';
import 'package:animal_record/features/home/domain/repositories/incoming_transfer_preview_repository.dart';

/// Session cache for the recipient's pending previews, including every page.
class IncomingTransferCache implements IncomingTransferPreviewRepository {
  final AnimalTransferRepository repository;
  final Future<void> Function(TransferItem)? preloadImage;
  late final BoundedMemoryCache<String, IncomingTransferSnapshot> _details;
  final _pending = <String, Future<IncomingTransferSnapshot>>{};
  final _detailTokens = <String, Object>{};
  final _photosReady = <String, int>{};
  @override
  TransferPage<TransferRequest>? pendingRequests;
  Future<TransferPage<TransferRequest>>? _pendingList;
  Future<void>? _warming;
  String? _accountId;
  int _generation = 0;
  int _listRevision = 0;

  IncomingTransferCache(
    this.repository, {
    this.preloadImage,
    int maxEntries = 64,
    int maxBytes = 4 * 1024 * 1024,
  }) {
    _details = BoundedMemoryCache(
      maxEntries: maxEntries,
      maxBytes: maxBytes,
      sizeOf: (snapshot) => snapshot.items.fold<int>(
        512,
        (size, item) =>
            size +
            item.props.whereType<String>().fold<int>(
              256,
              (bytes, value) => bytes + utf8.encode(value).length * 2,
            ),
      ),
      onEvicted: (id, _) => _photosReady.remove(id),
    );
  }

  @override
  void useAccount(String accountId) {
    if (_accountId == accountId) return;
    clear();
    _accountId = accountId;
  }

  @override
  void clear() {
    ++_generation;
    _accountId = null;
    pendingRequests = null;
    _pendingList = null;
    _warming = null;
    _details.clear();
    _pending.clear();
    _detailTokens.clear();
    ++_listRevision;
    _photosReady.clear();
  }

  @override
  IncomingTransferSnapshot? peek(String id) => _details[id];

  @override
  void invalidateDetail(String id) {
    _detailTokens.remove(id);
    _details.remove(id);
    _pending.remove(id);
    _photosReady.remove(id);
  }

  @override
  void removeRequest(String id) {
    ++_listRevision;
    _pendingList = null;
    invalidateDetail(id);
    final page = pendingRequests;
    if (page != null) {
      pendingRequests = TransferPage(
        page.items.where((request) => request.id != id).toList(),
        null,
      );
    }
  }

  @override
  Future<TransferPage<TransferRequest>> refreshPending() async {
    if (_pendingList case final pending?) return pending;
    final request = _readPending(_generation, _listRevision);
    _pendingList = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingList, request)) _pendingList = null;
    }
  }

  Future<TransferPage<TransferRequest>> _readPending(
    int generation,
    int revision,
  ) async {
    final requests = <TransferRequest>[];
    final seen = <String>{};
    String? cursor;
    do {
      final page = await repository.listRequests(
        direction: 'INCOMING',
        status: 'PENDING',
        cursor: cursor,
      );
      _check(generation);
      // A decision invalidates even a response that was already in flight.
      if (revision != _listRevision) return refreshPending();
      requests.addAll(
        page.items.where((request) => request.status == 'PENDING'),
      );
      cursor = page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw const FormatException('Paginación de solicitudes inválida.');
      }
    } while (cursor != null);
    final byId = {for (final request in requests) request.id: request};
    final previousVersions = {
      for (final request in pendingRequests?.items ?? const <TransferRequest>[])
        request.id: request.version,
    };
    for (final id in {..._details.keys, ..._pending.keys}) {
      final fresh = byId[id];
      if (fresh == null ||
          (_details[id]?.request.version ??
                  previousVersions[id] ??
                  fresh.version) <
              fresh.version) {
        invalidateDetail(id);
      }
    }
    return pendingRequests = TransferPage(List.unmodifiable(byId.values), null);
  }

  @override
  Future<IncomingTransferSnapshot> loadDetail(String id) async {
    if (_details[id] case final cached?) return cached;
    if (_pending[id] case final pending?) return pending;
    final token = Object();
    _detailTokens[id] = token;
    final request = _readDetail(id, _generation, token);
    _pending[id] = request;
    try {
      return await request;
    } finally {
      if (identical(_pending[id], request)) _pending.remove(id);
      if (identical(_detailTokens[id], token)) _detailTokens.remove(id);
    }
  }

  Future<IncomingTransferSnapshot> _readDetail(
    String id,
    int generation,
    Object token,
  ) async {
    final items = <String, TransferItem>{};
    final cursors = <String, String?>{};
    final seen = <String>{};
    TransferRequest? request;
    String? cursor;
    do {
      final detail = await repository.getDetail(id, cursor: cursor);
      _check(generation);
      if (!identical(_detailTokens[id], token)) {
        throw StateError('La solicitud cambió.');
      }
      if (request != null && request.version != detail.request.version) {
        throw const ApiException(
          message: 'La solicitud cambió durante la consulta.',
          statusCode: 409,
        );
      }
      request = detail.request;
      for (final item in detail.page.items) {
        items[item.id] = item;
        cursors[item.id] = cursor;
      }
      cursor = detail.page.nextCursor;
      if (cursor != null && !seen.add(cursor)) {
        throw const FormatException('Paginación del detalle inválida.');
      }
    } while (cursor != null);
    final result = IncomingTransferSnapshot(request, items.values, cursors);
    if (request.status == 'PENDING') {
      _details[id] = result;
    } else {
      removeRequest(id);
    }
    return result;
  }

  @override
  Future<void> prefetchPending() async {
    if (_warming case final warming?) return warming;
    final task = _prefetch(_generation);
    _warming = task;
    try {
      await task;
    } finally {
      if (identical(_warming, task)) _warming = null;
    }
  }

  Future<void> _prefetch(int generation) async {
    final requests = pendingRequests?.items ?? const <TransferRequest>[];
    var index = 0;
    Future<void> worker() async {
      while (generation == _generation && index < requests.length) {
        try {
          await loadDetail(requests[index++].id);
        } catch (_) {
          // A failed warm-up is retried normally when that request is opened.
        }
      }
    }

    await Future.wait(
      List.generate(requests.length.clamp(0, 2), (_) => worker()),
    );
    // Slow photos must not delay preparing the other requests' information.
    var photoIndex = 0;
    Future<void> photoWorker() async {
      while (generation == _generation && photoIndex < requests.length) {
        final snapshot = _details[requests[photoIndex++].id];
        if (snapshot == null) continue;
        try {
          if (_photosReady[snapshot.request.id] == snapshot.request.version) {
            continue;
          }
          for (final item in snapshot.items) {
            if (generation != _generation) return;
            if (!identical(_details[snapshot.request.id], snapshot)) break;
            await preloadImage?.call(item);
          }
          if (generation == _generation &&
              identical(_details[snapshot.request.id], snapshot)) {
            _photosReady[snapshot.request.id] = snapshot.request.version;
          }
        } catch (_) {
          // The normal image widget can retry or show its species fallback.
        }
      }
    }

    await Future.wait(
      List.generate(requests.length.clamp(0, 2), (_) => photoWorker()),
    );
  }

  @override
  void updatePage(String id, TransferDetail detail) {
    final previous = _details[id];
    if (previous == null) return;
    if (previous.request.version != detail.request.version ||
        detail.request.status != 'PENDING') {
      invalidateDetail(id);
      return;
    }
    final replacements = {for (final item in detail.page.items) item.id: item};
    _details[id] = IncomingTransferSnapshot(
      detail.request,
      previous.items.map((item) => replacements[item.id] ?? item),
      previous.itemCursors,
    );
  }

  void _check(int generation) {
    if (generation != _generation) throw StateError('La sesión cambió.');
  }
}
