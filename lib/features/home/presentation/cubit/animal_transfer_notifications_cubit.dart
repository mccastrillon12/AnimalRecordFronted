import 'package:animal_record/features/home/presentation/utils/transfer_error_feedback.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferNotificationsState {
  final List<NotificationItem> items;
  final String? cursor;
  final int? unreadCount;
  final bool loading;
  final String? error;
  const TransferNotificationsState({
    this.items = const [],
    this.cursor,
    this.unreadCount,
    this.loading = false,
    this.error,
  });
}

class TransferNotificationsCubit extends Cubit<TransferNotificationsState> {
  final AnimalTransferRepository repository;
  int _generation = 0;
  TransferNotificationsCubit(this.repository)
    : super(const TransferNotificationsState());

  Future<void> refresh() async {
    final generation = ++_generation;
    emit(
      TransferNotificationsState(
        items: state.items,
        cursor: state.cursor,
        unreadCount: state.unreadCount,
        loading: true,
      ),
    );
    try {
      final page = await repository.listNotifications();
      if (isClosed || generation != _generation) return;
      emit(
        TransferNotificationsState(
          items: page.items,
          cursor: page.nextCursor,
          unreadCount: state.unreadCount,
          loading: true,
        ),
      );
      try {
        final count = await repository.unreadNotificationCount();
        if (isClosed || generation != _generation) return;
        emit(
          TransferNotificationsState(
            items: page.items,
            cursor: page.nextCursor,
            unreadCount: count,
          ),
        );
      } catch (error) {
        if (isClosed || generation != _generation) return;
        emit(
          TransferNotificationsState(
            items: page.items,
            cursor: page.nextCursor,
            unreadCount: state.unreadCount,
            error: _message(error),
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          TransferNotificationsState(
            items: state.items,
            cursor: state.cursor,
            unreadCount: state.unreadCount,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final before = state;
    final generation = _generation;
    if (before.cursor == null || before.loading) return;
    emit(
      TransferNotificationsState(
        items: before.items,
        cursor: before.cursor,
        unreadCount: before.unreadCount,
        loading: true,
      ),
    );
    try {
      final page = await repository.listNotifications(cursor: before.cursor);
      if (!isClosed && generation == _generation) {
        emit(
          TransferNotificationsState(
            items: [...before.items, ...page.items],
            cursor: page.nextCursor,
            unreadCount: before.unreadCount,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && generation == _generation) {
        emit(
          TransferNotificationsState(
            items: before.items,
            cursor: before.cursor,
            unreadCount: before.unreadCount,
            error: _message(error),
          ),
        );
      }
    }
  }

  Future<void> markRead(String id) async {
    try {
      final item = await repository.markNotificationRead(id);
      if (isClosed) return;
      emit(
        TransferNotificationsState(
          items: state.items
              .map((current) => current.id == id ? item : current)
              .toList(growable: false),
          cursor: state.cursor,
          unreadCount: state.unreadCount,
        ),
      );
      try {
        final count = await repository.unreadNotificationCount();
        if (!isClosed) {
          emit(
            TransferNotificationsState(
              items: state.items,
              cursor: state.cursor,
              unreadCount: count,
            ),
          );
        }
      } catch (error) {
        if (!isClosed) {
          emit(
            TransferNotificationsState(
              items: state.items,
              cursor: state.cursor,
              unreadCount: state.unreadCount,
              error: _message(error),
            ),
          );
        }
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          TransferNotificationsState(
            items: state.items,
            cursor: state.cursor,
            unreadCount: state.unreadCount,
            error: _message(error),
          ),
        );
      }
    }
  }
}

String _message(Object error) => TransferErrorFeedback.message(
  error,
  fallback: 'No se pudieron consultar los avisos. Inténtalo de nuevo.',
);
