import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/usecases/get_animal_by_id_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

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
  int _generation = 0;
  TransferRequestsCubit(this.repository) : super(const TransferRequestsState());

  Future<void> load({String direction = 'INCOMING', String? filter}) async {
    final generation = ++_generation;
    emit(
      TransferRequestsState(
        direction: direction,
        filter: filter,
        loading: true,
      ),
    );
    try {
      final page = await repository.listRequests(
        direction: direction,
        status: filter,
      );
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
  const _DecisionIntent(
    this.id,
    this.version,
    this.acceptedAnimalIds,
    this.key,
  );
}

class TransferDetailCubit extends Cubit<TransferDetailState> {
  final AnimalTransferRepository repository;
  final String transferId;
  final GetAnimalByIdUseCase? getAnimalByIdUseCase;
  final Map<String, String> _animalImageUrls = {};
  final Set<String> _requestedAnimalImages = {};
  _DecisionIntent? _pendingDecision;
  Timer? _processingPoll;
  int _readGeneration = 0;

  TransferDetailCubit(
    this.repository,
    this.transferId, {
    this.getAnimalByIdUseCase,
  }) : super(const TransferDetailState());

  List<TransferItem> _withAnimalImages(List<TransferItem> items) => items
      .map((item) {
        final imageUrl = item.animalImageUrl?.trim();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _animalImageUrls[item.animalId] = imageUrl;
          return item;
        }
        final cachedUrl = _animalImageUrls[item.animalId];
        return cachedUrl == null ? item : item.withAnimalImageUrl(cachedUrl);
      })
      .toList(growable: false);

  void _loadMissingAnimalImages() {
    final useCase = getAnimalByIdUseCase;
    if (useCase == null) return;
    for (final item in state.items) {
      if ((item.animalImageUrl?.trim().isNotEmpty ?? false) ||
          !_requestedAnimalImages.add(item.animalId)) {
        continue;
      }
      unawaited(_loadAnimalImage(item.animalId, useCase));
    }
  }

  Future<void> _loadAnimalImage(
    String animalId,
    GetAnimalByIdUseCase useCase,
  ) async {
    try {
      final result = await useCase(animalId);
      var lookupFailed = false;
      final imageUrl = result.fold<String?>((_) {
        lookupFailed = true;
        return null;
      }, (animal) => animal.profilePictureUrl?.trim());
      if (lookupFailed) _requestedAnimalImages.remove(animalId);
      if (imageUrl == null || imageUrl.isEmpty || isClosed) return;
      _animalImageUrls[animalId] = imageUrl;
      final current = state;
      final updated = _withAnimalImages(current.items);
      emit(
        TransferDetailState(
          request: current.request,
          items: updated,
          cursor: current.cursor,
          selectedAnimalIds: current.selectedAnimalIds,
          loading: current.loading,
          error: current.error,
          canRetryDecision: current.canRetryDecision,
          submittingDecision: current.submittingDecision,
        ),
      );
    } catch (_) {
      _requestedAnimalImages.remove(animalId);
    }
  }

  Future<void> refresh() async {
    final generation = ++_readGeneration;
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
            items: _withAnimalImages(detail.page.items),
            cursor: detail.page.nextCursor,
            selectedAnimalIds: detail.request.version == previousVersion
                ? state.selectedAnimalIds
                : const {},
            canRetryDecision: _pendingDecision != null,
          ),
        );
        _loadMissingAnimalImages();
      }
    } catch (error) {
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
    if (cursor == null || state.loading) return;
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
      emit(
        TransferDetailState(
          request: detail.request,
          items: _withAnimalImages([...before.items, ...detail.page.items]),
          cursor: detail.page.nextCursor,
          selectedAnimalIds: before.selectedAnimalIds,
        ),
      );
      _loadMissingAnimalImages();
    } catch (error) {
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
    while (state.cursor != null) {
      final cursor = state.cursor;
      await loadMore();
      if (isClosed ||
          state.request?.version != version ||
          state.request?.status != 'PENDING' ||
          state.error != null ||
          state.cursor == cursor) {
        return false;
      }
    }
    return true;
  }

  void toggleAllAnimals() {
    if (state.request?.status != 'PENDING' || state.loading) return;
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
    if (state.request?.status != 'PENDING' || state.loading) return;
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

  Future<void> decide(List<String> acceptedAnimalIds) async {
    final request = state.request;
    if (request == null ||
        request.status != 'PENDING' ||
        state.loading ||
        _pendingDecision != null) {
      return;
    }
    _pendingDecision = _DecisionIntent(
      request.id,
      request.version,
      List.unmodifiable(acceptedAnimalIds),
      const Uuid().v4(),
    );
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
      );
      _pendingDecision = null;
      if (isClosed) return;
      emit(TransferDetailState(request: request, items: state.items));
      await refresh();
    } catch (error) {
      if (isClosed) return;
      final statusCode = error is ApiException ? error.statusCode : null;
      final data = error is ApiException ? error.data : null;
      final acceptanceDisabled =
          data is Map &&
          data['message'] ==
              'Transfer acceptance is not enabled; no decisions were applied';
      final uncertain =
          error is ApiException && (statusCode == null || statusCode == 503);
      if (!uncertain) _pendingDecision = null;
      final message = switch (statusCode) {
        409 when acceptanceDisabled =>
          'La aceptación está deshabilitada. La solicitud sigue intacta.',
        409 =>
          'El servidor rechazó la decisión por un conflicto (409). '
              'Se actualizará la solicitud.',
        _ when uncertain =>
          'Resultado incierto. Consulta el detalle o repite la misma decisión.',
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
      if (statusCode == 409) await refresh();
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
}) => error is ApiException ? error.message : fallback;
