import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/core/network/transfer_error_diagnostics.dart';
import 'package:animal_record/features/home/presentation/utils/transfer_error_feedback.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/transfer_comment_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:animal_record/features/home/domain/repositories/incoming_transfer_preview_repository.dart';

class TransferRequestsState {
  final String direction;
  final String? filter;
  final List<TransferRequest> requests;
  final String? cursor;
  final bool loading;
  final String? error;
  const TransferRequestsState({
    this.direction = 'INCOMING',
    this.filter,
    this.requests = const [],
    this.cursor,
    this.loading = false,
    this.error,
  });
}

class TransferRequestsCubit extends Cubit<TransferRequestsState> {
  final AnimalTransferRepository repository;
  final IncomingTransferPreviewRepository? previewCache;
  int _generation = 0;
  TransferRequestsCubit(this.repository, {this.previewCache})
    : super(const TransferRequestsState());

  Future<void> load({
    String direction = 'INCOMING',
    String? filter,
    bool forceRefresh = false,
  }) async {
    final generation = ++_generation;
    final usePendingCache =
        direction == 'INCOMING' && filter == 'PENDING' && previewCache != null;
    final cached = usePendingCache ? previewCache!.pendingRequests : null;
    if (!forceRefresh && cached != null) {
      emit(
        TransferRequestsState(
          direction: direction,
          filter: filter,
          requests: cached.items,
          cursor: cached.nextCursor,
        ),
      );
      return;
    }
    emit(
      TransferRequestsState(
        direction: direction,
        filter: filter,
        loading: true,
      ),
    );
    try {
      final page = usePendingCache
          ? await previewCache!.refreshPending()
          : await repository.listRequests(direction: direction, status: filter);
      if (!isClosed && generation == _generation) {
        emit(
          TransferRequestsState(
            direction: direction,
            filter: filter,
            requests: page.items,
            cursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          TransferRequestsState(
            direction: direction,
            filter: filter,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = state.cursor;
    if (cursor == null || state.loading) return;
    final before = state;
    final generation = _generation;
    emit(
      TransferRequestsState(
        direction: before.direction,
        filter: before.filter,
        requests: before.requests,
        cursor: cursor,
        loading: true,
      ),
    );
    try {
      final page = await repository.listRequests(
        direction: before.direction,
        status: before.filter,
        cursor: cursor,
      );
      if (!isClosed && generation == _generation) {
        emit(
          TransferRequestsState(
            direction: before.direction,
            filter: before.filter,
            requests: [...before.requests, ...page.items],
            cursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          TransferRequestsState(
            direction: before.direction,
            filter: before.filter,
            requests: before.requests,
            cursor: cursor,
            error: _message(error),
          ),
        );
      }
    }
  }
}

class TransferDetailState {
  final TransferRequest? request;
  final List<TransferItem> items;
  final String? cursor;
  final Set<String> selectedAnimalIds;
  final bool loading;
  final String? error;
  final bool canRetryDecision;
  final bool submittingDecision;
  const TransferDetailState({
    this.request,
    this.items = const [],
    this.cursor,
    this.selectedAnimalIds = const {},
    this.loading = false,
    this.error,
    this.canRetryDecision = false,
    this.submittingDecision = false,
  });

  bool get hasSingleAnimal =>
      items.length == 1 && cursor == null && (request?.animalCount ?? 0) <= 1;

  String? get singlePendingAnimalId =>
      hasSingleAnimal && items.single.status == 'PENDING'
      ? items.single.animalId
      : null;
}

class _DecisionIntent {
  final String id;
  final int version;
  final List<String> acceptedAnimalIds;
  final String key;
  final String? rejectionReasonCode;
  final String? rejectionComment;
  const _DecisionIntent(
    this.id,
    this.version,
    this.acceptedAnimalIds,
    this.key,
    this.rejectionReasonCode,
    this.rejectionComment,
  );
}

class TransferDetailCubit extends Cubit<TransferDetailState> {
  final AnimalTransferRepository repository;
  final String transferId;
  final IncomingTransferPreviewRepository? previewCache;
  final Map<String, String?> _itemCursors = {};
  final Map<String?, Future<void>> _imageRefreshes = {};
  final Map<String, DateTime> _imageRetries = {};
  _DecisionIntent? _pendingDecision;
  Timer? _processingPoll;
  int _readGeneration = 0;

  Future<List<TransferReason>> loadRejectionReasons() =>
      repository.getRejectionReasons();

  TransferDetailCubit(this.repository, this.transferId, {this.previewCache})
    : super(_cachedState(previewCache?.peek(transferId))) {
    final cached = previewCache?.peek(transferId);
    if (cached != null) _itemCursors.addAll(cached.itemCursors);
  }

  static TransferDetailState _cachedState(IncomingTransferSnapshot? cached) =>
      cached == null
      ? const TransferDetailState()
      : TransferDetailState(request: cached.request, items: cached.items);

  Future<void> initialize() async {
    if (state.request != null) return;
    final cache = previewCache;
    if (cache == null) return refresh();
    final generation = ++_readGeneration;
    emit(const TransferDetailState(loading: true));
    try {
      final cached = await cache.loadDetail(transferId);
      if (isClosed || generation != _readGeneration) return;
      _itemCursors
        ..clear()
        ..addAll(cached.itemCursors);
      emit(TransferDetailState(request: cached.request, items: cached.items));
      if (cached.request.status == 'PROCESSING') await refresh();
    } catch (error) {
      TransferErrorDiagnostics.recordDetailFailure(
        error,
        transferId: transferId,
      );
      if (isClosed || generation != _readGeneration) return;
      if (error is ApiException && error.statusCode == 409) {
        await refresh();
      } else {
        emit(TransferDetailState(error: _message(error)));
      }
    }
  }

  Future<void> refreshAnimalImage(String itemId, String failedUrl) async {
    if (isClosed) return;
    if (state.loading) {
      try {
        await stream.firstWhere((state) => !state.loading);
      } on StateError {
        return;
      }
    }
    if (isClosed || state.canRetryDecision || state.submittingDecision) return;
    if (!state.items.any(
          (item) => item.id == itemId && item.animalImageUrl == failedUrl,
        ) ||
        !_itemCursors.containsKey(itemId)) {
      return;
    }
    final last = _imageRetries[itemId];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _imageRetries[itemId] = DateTime.now();
    final cursor = _itemCursors[itemId];
    final existing = _imageRefreshes[cursor];
    if (existing != null) return existing;
    final refresh = _refreshImagePage(cursor);
    _imageRefreshes[cursor] = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_imageRefreshes[cursor], refresh)) {
        _imageRefreshes.remove(cursor);
      }
    }
  }

  Future<void> _refreshImagePage(String? cursor) async {
    final generation = _readGeneration;
    final version = state.request?.version;
    try {
      final detail = await repository.getDetail(transferId, cursor: cursor);
      if (state.loading) {
        try {
          await stream.firstWhere((state) => !state.loading);
        } on StateError {
          return;
        }
      }
      if (isClosed ||
          generation != _readGeneration ||
          state.canRetryDecision ||
          state.request?.version != version) {
        return;
      }
      if (detail.request.version != version) {
        await refresh();
        return;
      }
      final items = {for (final item in detail.page.items) item.id: item};
      previewCache?.updatePage(transferId, detail);
      emit(
        TransferDetailState(
          request: state.request,
          items: state.items.map((item) => items[item.id] ?? item).toList(),
          cursor: state.cursor,
          selectedAnimalIds: state.selectedAnimalIds,
          error: state.error,
          canRetryDecision: state.canRetryDecision,
        ),
      );
    } catch (error) {
      TransferErrorDiagnostics.recordDetailFailure(
        error,
        transferId: transferId,
      );
      if (!isClosed &&
          generation == _readGeneration &&
          !state.loading &&
          error is ApiException &&
          error.statusCode == 409) {
        await refresh();
      }
    }
  }

  Future<void> refresh() async {
    previewCache?.invalidateDetail(transferId);
    final generation = ++_readGeneration;
    _imageRetries.clear();
    _imageRefreshes.clear();
    final previousVersion = state.request?.version;
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        cursor: state.cursor,
        selectedAnimalIds: state.selectedAnimalIds,
        loading: true,
        canRetryDecision: _pendingDecision != null,
      ),
    );
    try {
      final detail = await repository.getDetail(transferId);
      if (isClosed || generation != _readGeneration) return;
      if (detail.request.status != 'PENDING' &&
          detail.request.status != state.request?.status) {
        previewCache?.removeRequest(transferId);
      }
      _itemCursors
        ..clear()
        ..addEntries(detail.page.items.map((item) => MapEntry(item.id, null)));
      if (detail.request.status == 'PROCESSING') {
        _processingPoll ??= Timer.periodic(const Duration(seconds: 5), (_) {
          if (!isClosed && !state.loading) refresh();
        });
      } else {
        _processingPoll?.cancel();
        _processingPoll = null;
      }
      if (_pendingDecision != null &&
          detail.request.status != 'PENDING' &&
          detail.request.version > _pendingDecision!.version) {
        _pendingDecision = null;
      }
      if (!isClosed && generation == _readGeneration) {
        emit(
          TransferDetailState(
            request: detail.request,
            items: detail.page.items,
            cursor: detail.page.nextCursor,
            selectedAnimalIds: detail.request.version == previousVersion
                ? state.selectedAnimalIds
                : const {},
            canRetryDecision: _pendingDecision != null,
          ),
        );
      }
    } catch (error) {
      TransferErrorDiagnostics.recordDetailFailure(
        error,
        transferId: transferId,
      );
      if (!isClosed && generation == _readGeneration) {
        emit(
          TransferDetailState(
            request: state.request,
            items: state.items,
            cursor: state.cursor,
            selectedAnimalIds: state.selectedAnimalIds,
            error: _message(error),
            canRetryDecision: _pendingDecision != null,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = state.cursor;
    if (cursor == null || state.loading || _pendingDecision != null) return;
    final before = state;
    final generation = _readGeneration;
    emit(
      TransferDetailState(
        request: before.request,
        items: before.items,
        cursor: cursor,
        selectedAnimalIds: before.selectedAnimalIds,
        loading: true,
      ),
    );
    try {
      final detail = await repository.getDetail(transferId, cursor: cursor);
      if (isClosed || generation != _readGeneration) return;
      if (detail.request.version != before.request?.version) {
        await refresh();
        return;
      }
      _itemCursors.addEntries(
        detail.page.items.map((item) => MapEntry(item.id, cursor)),
      );
      emit(
        TransferDetailState(
          request: detail.request,
          items: [...before.items, ...detail.page.items],
          cursor: detail.page.nextCursor,
          selectedAnimalIds: before.selectedAnimalIds,
        ),
      );
    } catch (error) {
      TransferErrorDiagnostics.recordDetailFailure(
        error,
        transferId: transferId,
      );
      if (isClosed || generation != _readGeneration) return;
      if (error is ApiException && error.statusCode == 409) {
        await refresh();
        return;
      }
      if (!isClosed) {
        emit(
          TransferDetailState(
            request: before.request,
            items: before.items,
            cursor: cursor,
            selectedAnimalIds: before.selectedAnimalIds,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<bool> loadAllAnimals() async {
    final version = state.request?.version;
    if (version == null || state.loading) return false;
    final seen = <String>{};
    while (state.cursor != null) {
      final cursor = state.cursor;
      if (!seen.add(cursor!)) return false;
      await loadMore();
      if (isClosed ||
          state.request?.version != version ||
          state.request?.status != 'PENDING' ||
          state.error != null ||
          state.cursor == cursor) {
        return false;
      }
    }
    final count = state.request?.animalCount ?? 0;
    final loadedCount = state.items.map((item) => item.animalId).toSet().length;
    if (count > 0 && loadedCount != count) {
      emit(
        TransferDetailState(
          request: state.request,
          items: state.items,
          cursor: state.cursor,
          selectedAnimalIds: state.selectedAnimalIds,
          error:
              'No se pudieron cargar todos los animales. Actualiza la solicitud antes de decidir.',
        ),
      );
      return false;
    }
    return state.request?.status == 'PENDING';
  }

  void toggleAllAnimals() {
    if (state.request?.status != 'PENDING' ||
        state.loading ||
        state.canRetryDecision) {
      return;
    }
    final pendingIds = state.items
        .where((item) => item.status == 'PENDING')
        .map((item) => item.animalId)
        .toSet();
    if (pendingIds.isEmpty) return;
    final selected = {...state.selectedAnimalIds};
    if (selected.containsAll(pendingIds)) {
      selected.removeAll(pendingIds);
    } else {
      selected.addAll(pendingIds);
    }
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        cursor: state.cursor,
        selectedAnimalIds: selected,
      ),
    );
  }

  void toggleAnimal(String animalId) {
    if (state.request?.status != 'PENDING' ||
        state.loading ||
        state.canRetryDecision) {
      return;
    }
    if (!state.items.any(
      (item) => item.animalId == animalId && item.status == 'PENDING',
    )) {
      return;
    }
    final selected = {...state.selectedAnimalIds};
    if (!selected.add(animalId)) selected.remove(animalId);
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        cursor: state.cursor,
        selectedAnimalIds: selected,
      ),
    );
  }

  Future<void> decide(
    List<String> acceptedAnimalIds, {
    TransferReason? rejectionReason,
    String? rejectionComment,
  }) async {
    final request = state.request;
    if (request == null ||
        request.status != 'PENDING' ||
        state.loading ||
        _pendingDecision != null) {
      return;
    }
    // A decision covers every page, including animals that were never visible.
    if (!await loadAllAnimals() ||
        isClosed ||
        _pendingDecision != null ||
        state.request?.version != request.version ||
        state.request?.status != 'PENDING') {
      return;
    }
    final pendingIds = state.items
        .where((item) => item.status == 'PENDING')
        .map((item) => item.animalId)
        .toSet();
    final accepted = acceptedAnimalIds.toSet();
    String? comment;
    String? validationError;
    if (pendingIds.isEmpty ||
        !pendingIds.containsAll(accepted) ||
        accepted.length != acceptedAnimalIds.length) {
      validationError = 'La selección de animales no es válida.';
    } else if (accepted.length < pendingIds.length) {
      if (rejectionReason == null) {
        validationError = 'Selecciona el motivo de rechazo.';
      } else {
        try {
          comment = TransferCommentPolicy.normalize(
            rejectionReason.code,
            rejectionComment,
          );
        } on FormatException catch (error) {
          validationError = error.message;
        }
      }
    } else if (rejectionReason != null || rejectionComment != null) {
      validationError = 'La aceptación total no admite motivo de rechazo.';
    }
    if (validationError != null) {
      emit(
        TransferDetailState(
          request: state.request,
          items: state.items,
          cursor: state.cursor,
          selectedAnimalIds: state.selectedAnimalIds,
          error: validationError,
        ),
      );
      return;
    }
    _pendingDecision = _DecisionIntent(
      request.id,
      request.version,
      List.unmodifiable(acceptedAnimalIds),
      const Uuid().v4(),
      rejectionReason?.code,
      comment,
    );
    previewCache?.invalidateDetail(transferId);
    await retryDecision();
  }

  Future<void> retryDecision() async {
    final intent = _pendingDecision;
    if (intent == null || state.loading) return;
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        cursor: state.cursor,
        selectedAnimalIds: state.selectedAnimalIds,
        loading: true,
        submittingDecision: true,
      ),
    );
    try {
      final request = await repository.decide(
        id: intent.id,
        expectedVersion: intent.version,
        acceptedAnimalIds: intent.acceptedAnimalIds,
        idempotencyKey: intent.key,
        rejectionReasonCode: intent.rejectionReasonCode,
        rejectionComment: intent.rejectionComment,
      );
      previewCache?.removeRequest(transferId);
      _pendingDecision = null;
      if (isClosed) return;
      emit(TransferDetailState(request: request, items: state.items));
      await refresh();
    } catch (error) {
      TransferErrorDiagnostics.recordDecisionFailure(
        error,
        transferId: intent.id,
      );
      if (isClosed) return;
      final statusCode = error is ApiException ? error.statusCode : null;
      final uncertain =
          error is! ApiException ||
          statusCode == null ||
          statusCode == 408 ||
          statusCode >= 500 ||
          statusCode < 300;
      if (!uncertain) _pendingDecision = null;
      final message = switch (statusCode) {
        409 =>
          'No pudimos completar la acción. Revisa la solicitud e inténtalo de nuevo.',
        _ when uncertain =>
          'Aún no pudimos confirmar tu respuesta. Revisa la solicitud antes de reintentar.',
        _ => _message(error, fallback: 'No se pudo enviar la decisión.'),
      };
      emit(
        TransferDetailState(
          request: state.request,
          items: state.items,
          cursor: state.cursor,
          selectedAnimalIds: state.selectedAnimalIds,
          error: message,
          canRetryDecision: uncertain,
        ),
      );
      if (statusCode == 409 || uncertain) await refresh();
    }
  }

  @override
  Future<void> close() {
    _processingPoll?.cancel();
    _pendingDecision = null;
    return super.close();
  }
}

String _message(
  Object error, {
  String fallback = 'No se pudo consultar la transferencia.',
}) => TransferErrorFeedback.message(error, fallback: fallback);
