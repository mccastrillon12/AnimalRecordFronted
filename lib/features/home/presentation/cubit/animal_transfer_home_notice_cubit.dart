import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:animal_record/features/home/domain/repositories/incoming_transfer_preview_repository.dart';

class TransferHomeNoticeCubit extends Cubit<TransferRequest?> {
  final AnimalTransferRepository repository;
  final IncomingTransferPreviewRepository? previewCache;
  bool _loading = false;

  TransferHomeNoticeCubit(this.repository, {this.previewCache}) : super(null);

  Future<void> refresh() async {
    if (_loading || isClosed) return;
    _loading = true;
    try {
      final page = previewCache != null
          ? await previewCache!.refreshPending()
          : await repository.listRequests(
              direction: 'INCOMING',
              status: 'PENDING',
            );
      if (!isClosed && previewCache != null) {
        unawaited(previewCache!.prefetchPending());
      }
      if (!isClosed) {
        emit(
          page.items
              .where((request) => request.status == 'PENDING')
              .firstOrNull,
        );
      }
    } catch (_) {
      // Keep the last confirmed value if this refresh cannot reach the server.
    } finally {
      _loading = false;
    }
  }
}
