import 'package:animal_record/core/network/api_exception.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferHistoryState {
  final List<OwnershipPeriod> periods;
  final String? periodsCursor;
  final OwnershipPeriod? selectedPeriod;
  final List<HistoricalEntry> entries;
  final String? entriesCursor;
  final bool loading;
  final String? error;
  const TransferHistoryState({
    this.periods = const [],
    this.periodsCursor,
    this.selectedPeriod,
    this.entries = const [],
    this.entriesCursor,
    this.loading = false,
    this.error,
  });
}

class TransferHistoryCubit extends Cubit<TransferHistoryState> {
  final AnimalTransferRepository repository;
  int _generation = 0;
  TransferHistoryCubit(this.repository) : super(const TransferHistoryState());

  Future<void> loadPeriods() async {
    final generation = ++_generation;
    emit(const TransferHistoryState(loading: true));
    try {
      final page = await repository.listHistory();
      if (!isClosed && generation == _generation) {
        emit(
          TransferHistoryState(
            periods: page.items,
            periodsCursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(TransferHistoryState(error: _message(error)));
      }
    }
  }

  Future<void> loadMorePeriods() async {
    final before = state;
    final generation = _generation;
    if (before.periodsCursor == null || before.loading) return;
    emit(
      TransferHistoryState(
        periods: before.periods,
        periodsCursor: before.periodsCursor,
        loading: true,
      ),
    );
    try {
      final page = await repository.listHistory(cursor: before.periodsCursor);
      if (!isClosed && generation == _generation) {
        emit(
          TransferHistoryState(
            periods: [...before.periods, ...page.items],
            periodsCursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          TransferHistoryState(
            periods: before.periods,
            periodsCursor: before.periodsCursor,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<void> openPeriod(OwnershipPeriod period) async {
    final generation = ++_generation;
    emit(
      TransferHistoryState(
        periods: state.periods,
        periodsCursor: state.periodsCursor,
        selectedPeriod: period,
        loading: true,
      ),
    );
    try {
      final page = await repository.getHistory(
        period.periodId,
        period.publicationHash,
      );
      if (!isClosed && generation == _generation) {
        emit(
          TransferHistoryState(
            periods: state.periods,
            periodsCursor: state.periodsCursor,
            selectedPeriod: period,
            entries: page.items,
            entriesCursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (isClosed || generation != _generation) return;
      if (error is ApiException && error.statusCode == 409) {
        await loadPeriods();
        return;
      }
      if (!isClosed) {
        emit(
          TransferHistoryState(
            periods: state.periods,
            periodsCursor: state.periodsCursor,
            selectedPeriod: period,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<void> loadMoreEntries() async {
    final before = state;
    final generation = _generation;
    final period = before.selectedPeriod;
    if (period == null || before.entriesCursor == null || before.loading) {
      return;
    }
    emit(
      TransferHistoryState(
        periods: before.periods,
        periodsCursor: before.periodsCursor,
        selectedPeriod: period,
        entries: before.entries,
        entriesCursor: before.entriesCursor,
        loading: true,
      ),
    );
    try {
      final page = await repository.getHistory(
        period.periodId,
        period.publicationHash,
        cursor: before.entriesCursor,
      );
      if (!isClosed && generation == _generation) {
        emit(
          TransferHistoryState(
            periods: before.periods,
            periodsCursor: before.periodsCursor,
            selectedPeriod: period,
            entries: [...before.entries, ...page.items],
            entriesCursor: page.nextCursor,
          ),
        );
      }
    } catch (error) {
      if (isClosed || generation != _generation) return;
      if (error is ApiException && error.statusCode == 409) {
        await loadPeriods();
        return;
      }
      if (!isClosed) {
        emit(
          TransferHistoryState(
            periods: before.periods,
            periodsCursor: before.periodsCursor,
            selectedPeriod: period,
            entries: before.entries,
            entriesCursor: before.entriesCursor,
            error: _message(error),
          ),
        );
      }
    }
  }

  void closePeriod() {
    ++_generation;
    emit(
      TransferHistoryState(
        periods: state.periods,
        periodsCursor: state.periodsCursor,
      ),
    );
  }

  Future<List<int>> download(HistoricalEntry entry, HistoricalFile file) async {
    final period = state.selectedPeriod;
    if (period == null) throw StateError('No hay período seleccionado');
    try {
      return await repository.downloadHistoricalFile(
        periodId: period.periodId,
        publicationHash: period.publicationHash,
        entryId: entry.entryId,
        fileId: file.fileId,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 409) await loadPeriods();
      rethrow;
    }
  }
}

String _message(Object error) => error is ApiException
    ? error.message
    : 'No se pudo consultar el histórico.';
