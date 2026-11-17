import 'dart:async';

import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
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
  final Set<String> acceptedAnimalIds;
  final bool loading;
  final String? error;
  final bool canRetryDecision;
  const TransferDetailState({
    this.request,
    this.items = const [],
    this.cursor,
    this.acceptedAnimalIds = const {},
    this.loading = false,
    this.error,
    this.canRetryDecision = false,
  });
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
  _DecisionIntent? _pendingDecision;
  Timer? _processingPoll;
  int _readGeneration = 0;

  TransferDetailCubit(this.repository, this.transferId)
    : super(const TransferDetailState());

  Future<void> refresh() async {
    final generation = ++_readGeneration;
    final previousVersion = state.request?.version;
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        acceptedAnimalIds: state.acceptedAnimalIds,
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
            items: detail.page.items,
            cursor: detail.page.nextCursor,
            acceptedAnimalIds: detail.request.version == previousVersion
                ? state.acceptedAnimalIds
                : const {},
            canRetryDecision: _pendingDecision != null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _readGeneration) {
        emit(
          TransferDetailState(
            request: state.request,
            items: state.items,
            cursor: state.cursor,
            acceptedAnimalIds: state.acceptedAnimalIds,
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
        acceptedAnimalIds: before.acceptedAnimalIds,
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
          items: [...before.items, ...detail.page.items],
          cursor: detail.page.nextCursor,
          acceptedAnimalIds: before.acceptedAnimalIds,
        ),
      );
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
            acceptedAnimalIds: before.acceptedAnimalIds,
            error: _message(error),
          ),
        );
      }
    }
  }

  void toggleAnimal(String animalId) {
    if (state.request?.status != 'PENDING' || state.loading) return;
    if (!state.items.any(
      (item) => item.animalId == animalId && item.status == 'PENDING',
    )) {
      return;
    }
    final selected = {...state.acceptedAnimalIds};
    if (!selected.add(animalId)) selected.remove(animalId);
    emit(
      TransferDetailState(
        request: state.request,
        items: state.items,
        cursor: state.cursor,
        acceptedAnimalIds: selected,
      ),
    );
  }

  Future<void> decide(List<String> acceptedAnimalIds) async {
    final request = state.request;
    if (request == null || request.status != 'PENDING' || state.loading) return;
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
        acceptedAnimalIds: state.acceptedAnimalIds,
        loading: true,
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
      final uncertain =
          error is ApiException &&
          (error.statusCode == null || error.statusCode == 503);
      if (!uncertain) _pendingDecision = null;
      emit(
        TransferDetailState(
          request: state.request,
          items: state.items,
          cursor: state.cursor,
          acceptedAnimalIds: state.acceptedAnimalIds,
          error: uncertain
              ? 'Resultado incierto. Consulta el detalle o repite la misma decisión.'
              : _message(error),
          canRetryDecision: uncertain,
        ),
      );
      if (error is ApiException && error.statusCode == 409) await refresh();
    }
  }

  @override
  Future<void> close() {
    _processingPoll?.cancel();
    _pendingDecision = null;
    return super.close();
  }
}

String _message(Object error) => error is ApiException
    ? error.message
    : 'No se pudo consultar la transferencia.';
